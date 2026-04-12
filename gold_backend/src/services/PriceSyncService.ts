import { prisma } from "../lib/prisma";
import { Prisma } from "@prisma/client";
import ProductService from "./ProductService";
import * as cron from "node-cron";

const BINANCE_PRICE_URL = "https://api.binance.com/api/v3/ticker/price?symbol=PAXGUSDT";
const EXCHANGE_RATE_URL = "https://api.exchangerate-api.com/v4/latest/USD"; 
const TROY_OUNCE_TO_GRAMS = 31.1035;
const IMPORT_DUTY_MULTIPLIER = 1.06;
const GST_MULTIPLIER = 1.03;

class PriceSyncService {
  private syncJob: cron.ScheduledTask | null = null;

  /**
   * Start the background sync task using a cron scheduler
   * @param intervalHours Frequency of sync (default every 2 hours at the start of the hour)
   */
  start(intervalHours: number = 2) {
    console.log(`📡 [PriceSync] Starting Automated Gold Price Sync (Every ${intervalHours} hours)...`);
    
    // Initial sync on startup
    this.performSync().catch(err => console.error("❌ [PriceSync] Initial startup sync failed:", err));

    // Schedule periodic sync using cron
    // '0 */2 * * *' means "At minute 0 of every 2nd hour"
    const cronSchedule = `0 */${intervalHours} * * *`;
    
    if (this.syncJob) this.syncJob.stop();
    this.syncJob = cron.schedule(cronSchedule, () => {
      this.performSync().catch(err => console.error("❌ [PriceSync] Scheduled cron sync failed:", err));
    });
    
    console.log(`📅 [PriceSync] Schedule initialized: ${cronSchedule}`);
  }

  /**
   * Fetch live data and update the database
   */
  async performSync() {
    console.log("🔄 [PriceSync] Fetching latest market data...");
    
    try {
      // 1. Fetch Global Spot (Troy Ounce) from Binance (PAXG is 1:1 with Gold Ounce)
      const priceRes = await fetch(BINANCE_PRICE_URL);
      if (!priceRes.ok) throw new Error("Binance API unavailable");
      const priceData: any = await priceRes.json();
      const goldPriceUSDPerOunce = parseFloat(priceData.price);

      // 2. Fetch USD to INR rate
      let usdToInr = 83.5; 
      try {
        const exRes = await fetch(EXCHANGE_RATE_URL);
        if (exRes.ok) {
          const exData: any = await exRes.json();
          usdToInr = exData.rates.INR;
        }
      } catch (e) {
        console.warn("⚠️ [PriceSync] Using fallback exchange rate due to API error");
      }

      // 3. Indian Market Math: Calculate Institutional Base Price Per Gram (Incl. Duty & 3% GST)
      // Formula: (Global Price / 31.1035) * USD_INR * 1.06 (Import Duty) * 1.03 (GST)
      const basePricePerGramINR = (goldPriceUSDPerOunce / TROY_OUNCE_TO_GRAMS) * usdToInr;
      const sellPricePerGram = basePricePerGramINR * IMPORT_DUTY_MULTIPLIER * GST_MULTIPLIER;

      // 4. Fetch Buyback Margin from Settings
      const marginSetting = await prisma.setting.findUnique({ where: { key: "buyback_margin" } });
      const marginPercent = marginSetting ? parseFloat(marginSetting.value) : 3.0;
      const buyPricePerGram = sellPricePerGram * (1 - marginPercent / 100);

      // 5. Update Database
      const newPrice = await ProductService.updateGoldPrice(
        Number(buyPricePerGram.toFixed(2)),
        Number(sellPricePerGram.toFixed(2))
      );

      console.log(`✅ [PriceSync] Successfully synced! Sell: ₹${sellPricePerGram.toFixed(2)} | Buy: ₹${buyPricePerGram.toFixed(2)} (Margin: ${marginPercent}%)`);
      return newPrice;

    } catch (error) {
      console.error("❌ [PriceSync] Critical price sync error:", error);
      throw error;
    }
  }

  /**
   * Stop the background sync task
   */
  stop() {
    if (this.syncJob) {
      this.syncJob.stop();
      this.syncJob = null;
    }
  }
}

export default new PriceSyncService();

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
    console.log("🔄 [PriceSync] Triggering automated market sync...");
    try {
      const newPrice = await ProductService.performLiveMarketSync();
      console.log(`✅ [PriceSync] Synced! Sell: ₹${Number(newPrice.sellPrice).toFixed(2)} | Buy: ₹${Number(newPrice.buyPrice).toFixed(2)}`);
      return newPrice;
    } catch (error) {
      console.error("❌ [PriceSync] Scheduled sync failed:", error);
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

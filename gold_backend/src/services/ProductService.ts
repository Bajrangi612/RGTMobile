import { prisma } from "../lib/prisma";
import { Product, GoldPrice, Prisma } from "@prisma/client";

class ProductService {
  /**
   * Get all active products
   */
  async getAllProducts(categoryId?: string, includeInactive: boolean = false, page: number = 1, limit: number = 50) {
    const where: any = includeInactive ? {} : { isActive: true };
    if (categoryId) {
      where.categoryId = categoryId;
    }

    const skip = (page - 1) * limit;

    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where,
        skip,
        take: limit,
      include: {
        category: true,
        _count: {
          select: {
            orders: {
              where: { status: 'ORDER_CONFIRMED' }
            }
          }
        }
        }
      }),
      prisma.product.count({ where })
    ]);

    return {
      products,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Get a single product by ID
   */
  async getProductById(id: string) {
    return await prisma.product.findUnique({
      where: { id: id },
    });
  }

  async createProduct(data: {
    name: string;
    description?: string;
    weight: number;
    purity: string;
    imageUrl?: string;
    stock: number;
    categoryId?: string;
    makingCharges?: number;
    fixedPrice?: number;
  }) {
    return await prisma.product.create({
      data: {
        ...data,
        weight: new Prisma.Decimal(data.weight),
        makingCharges: new Prisma.Decimal(data.makingCharges || 0),
        fixedPrice: new Prisma.Decimal(data.fixedPrice || 0),
      },
    });
  }

  /**
   * Update an existing product
   */
  async updateProduct(id: string, data: Partial<{
    name: string;
    description: string;
    weight: number;
    purity: string;
    imageUrl: string;
    stock: number;
    categoryId: string;
    isActive: boolean;
    makingCharges: number;
    fixedPrice: number;
  }>) {
    const updateData: any = { ...data };
    if (data.weight !== undefined) {
      updateData.weight = new Prisma.Decimal(data.weight);
    }
    if (data.makingCharges !== undefined) {
      updateData.makingCharges = new Prisma.Decimal(data.makingCharges);
    }
    if (data.fixedPrice !== undefined) {
      updateData.fixedPrice = new Prisma.Decimal(data.fixedPrice);
    }

    return await prisma.product.update({
      where: { id },
      data: updateData,
    });
  }

  /**
   * Delete a product (Soft delete by setting isActive to false)
   */
  async deleteProduct(id: string) {
    return await prisma.product.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /**
   * Get the latest gold price from the database (with fallback)
   */
  async getLatestGoldPrice(): Promise<GoldPrice | any> {
    const price = await prisma.goldPrice.findFirst({
      orderBy: { timestamp: "desc" },
    });
    
    if (price) return price;

    // AUTO-INITIALIZE: If DB is empty, fetch and save immediately
    console.log("⚠️ [ProductService] Gold Price DB is empty. Initializing live fetch...");
    try {
      return await this.performLiveMarketSync();
    } catch (e) {
      console.warn("⚠️ [ProductService] Initial fetch failed, using safe fallback.");
      return {
        buyPrice: new Prisma.Decimal(7500.0),
        sellPrice: new Prisma.Decimal(7600.0),
        timestamp: new Date(),
      };
    }
  }

  /**
   * Fetch live data from global markets and update the database
   */
  async performLiveMarketSync() {
    const BINANCE_PRICE_URL = "https://api.binance.com/api/v3/ticker/price?symbol=PAXGUSDT";
    const EXCHANGE_RATE_URL = "https://api.exchangerate-api.com/v4/latest/USD";
    const TROY_OUNCE_TO_GRAMS = 31.1035;
    const IMPORT_DUTY_MULTIPLIER = 1.06;
    const GST_MULTIPLIER = 1.03;

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
        console.warn("⚠️ [ProductService] Using fallback exchange rate due to API error");
      }

      // 3. Indian Market Math: Calculate Institutional Base Price Per Gram
      const basePricePerGramINR = (goldPriceUSDPerOunce / TROY_OUNCE_TO_GRAMS) * usdToInr;
      const sellPricePerGram = basePricePerGramINR * IMPORT_DUTY_MULTIPLIER * GST_MULTIPLIER;

      // 4. Fetch Buyback Margin from Settings
      const marginSetting = await prisma.setting.findUnique({ where: { key: "buyback_margin" } });
      const marginPercent = marginSetting ? parseFloat(marginSetting.value) : 3.0;
      const buyPricePerGram = sellPricePerGram * (1 - marginPercent / 100);

      // 5. Update Database
      return await this.updateGoldPrice(
        Number(buyPricePerGram.toFixed(2)),
        Number(sellPricePerGram.toFixed(2))
      );
    } catch (error) {
      console.error("❌ [ProductService] Live market sync failed:", error);
      throw error;
    }
  }

  /**
   * Calculate the current price of a product including 3% GST
   * @param product The product object
   * @param livePrice The current gold price per gram
   * @returns object with breaking down of price
   */
  async calculateProductPrice(product: any, livePrice: number) {
    const weight = Number(product.weight);
    const fixedPrice = Number(product.fixedPrice || 0);

    // Fetch Dynamic Pricing Settings
    const gstSetting = await prisma.setting.findUnique({ where: { key: 'gst_rate' } });
    const makingChargeSetting = await prisma.setting.findUnique({ where: { key: 'making_charge_percent' } });
    const makingGstSetting = await prisma.setting.findUnique({ where: { key: 'gst_on_making_percent' } });
    const discountSetting = await prisma.setting.findUnique({ where: { key: 'global_discount_percent' } });

    const GOLD_GST_RATE = (gstSetting ? parseFloat(gstSetting.value) : 3.0) / 100;
    const MAKING_CHARGE_RATE = (makingChargeSetting ? parseFloat(makingChargeSetting.value) : 6.0) / 100;
    const MAKING_GST_RATE = (makingGstSetting ? parseFloat(makingGstSetting.value) : 5.0) / 100;
    const GLOBAL_DISCOUNT_RATE = (discountSetting ? parseFloat(discountSetting.value) : 0.0) / 100;

    const marketValue = weight * livePrice;
    let goldValue: number;
    let discountedGoldValue: number = marketValue;
    let makingChargeValue: number = 0;
    let gstOnMaking: number = 0;
    let goldGst: number = 0;
    let discountAmount: number = 0;
    
    if (fixedPrice > 0) {
      goldValue = fixedPrice;
      discountedGoldValue = fixedPrice;
    } else {
      // 1. Market Gold Value: Live Price * Weight
      // 2. Discounted Value: Market Value - Discount %
      discountAmount = marketValue * GLOBAL_DISCOUNT_RATE;
      discountedGoldValue = marketValue - discountAmount;
      
      // 3. GST (IGST & CGST): % of Discounted gold value
      goldGst = discountedGoldValue * GOLD_GST_RATE;
      
      // 4. Making Charge: % of Market Gold Value
      makingChargeValue = marketValue * MAKING_CHARGE_RATE;
      
      // 5. GST on Making: % of Making Charge
      gstOnMaking = makingChargeValue * MAKING_GST_RATE;
    }
    
    // 6. Final Payable Amount
    const total = discountedGoldValue + goldGst + makingChargeValue + gstOnMaking;

    return {
      marketPrice: Number(marketValue.toFixed(2)),
      discountAmount: Number(discountAmount.toFixed(2)),
      discountedGoldValue: Number(discountedGoldValue.toFixed(2)),
      goldGst: Number(goldGst.toFixed(2)),
      makingCharges: Number(makingChargeValue.toFixed(2)),
      makingGst: Number(gstOnMaking.toFixed(2)),
      gstAmount: Number((goldGst + gstOnMaking).toFixed(2)),
      total: Number(total.toFixed(2)),
      purity: product.purity,
      weight: weight,
      ratePerGram: livePrice.toFixed(2),
      discountPercent: (discountSetting ? parseFloat(discountSetting.value) : 0.0),
    };
  }

  /**
   * Update all products that are not using a fixedPrice logic? 
   * Actually, the user wants "it should also be updated in product fix price x gram"
   */
  async syncAllProductPrices(liveSellPrice: number) {
    console.log(`🔄 Syncing all products with Live Price: ₹${liveSellPrice}...`);
    // This is more of a placeholder as effectivePrice is calculated on-the-fly, 
    // but if we had stored totals, we would update them here.
  }
  /**
   * Update the live gold price
   */
  async updateGoldPrice(buyPrice: number, sellPrice: number) {
    const newPrice = await prisma.goldPrice.create({
      data: {
        buyPrice: new Prisma.Decimal(buyPrice),
        sellPrice: new Prisma.Decimal(sellPrice),
        timestamp: new Date(),
      },
    });

    // Auto-sync fixedPrice products linearly based on the new market rate (per gram)
    // formula: fixedPrice = (weight * sellPrice) + makingCharges
    const productsToUpdate = await prisma.product.findMany({
      where: { fixedPrice: { gt: 0 } },
    });

    for (const product of productsToUpdate) {
      const weight = Number(product.weight);
      const makingCharges = Number(product.makingCharges || 0);
      const updatedFixedPrice = (weight * sellPrice) + makingCharges;

      await prisma.product.update({
        where: { id: product.id },
        data: {
          fixedPrice: new Prisma.Decimal(updatedFixedPrice),
        },
      });
    }

    return newPrice;
  }

  /**
   * Get historical gold price data
   */
  async getGoldPriceHistory(limit: number = 24): Promise<any[]> {
    const prices = await prisma.goldPrice.findMany({
      orderBy: { timestamp: "desc" },
      take: limit,
    });

    // Return in chronological order (oldest first for charts)
    return prices.reverse().map(p => ({
      price: Number(p.sellPrice),
      timestamp: p.timestamp,
    }));
  }
}

export default new ProductService();

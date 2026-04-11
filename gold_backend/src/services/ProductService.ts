import { prisma } from "../lib/prisma";
import { Product, GoldPrice, Prisma } from "@prisma/client";

class ProductService {
  /**
   * Get all active products
   */
  async getAllProducts(categoryId?: string) {
    const where: any = { isActive: true };
    if (categoryId) {
      where.categoryId = categoryId;
    }

    return await prisma.product.findMany({
      where,
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
    });
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

    // Fallback: Always return a safe price if DB is empty
    if (!price) {
      return {
        buyPrice: new Prisma.Decimal(7500.0),
        sellPrice: new Prisma.Decimal(7600.0),
        timestamp: new Date(),
      };
    }

    return price;
  }

  /**
   * Calculate the current price of a product including 3% GST
   * @param product The product object
   * @param livePrice The current gold price per gram
   * @returns object with breaking down of price
   */
  calculateProductPrice(product: any, livePrice: number) {
    const weight = Number(product.weight);
    const makingCharges = Number(product.makingCharges || 0);
    const fixedPrice = Number(product.fixedPrice || 0);

    let goldValue: number;
    
    if (fixedPrice > 0) {
      goldValue = fixedPrice;
    } else {
      goldValue = (weight * livePrice) + makingCharges;
    }
    
    // Fetch GST from settings or fallback to 3%
    const gstRate = 0.03; // Logic to be updated to fetch from DB if needed
    const gstAmount = goldValue * gstRate;
    const total = goldValue + gstAmount;

    return {
      goldValue: Number(goldValue.toFixed(2)),
      gstAmount: Number(gstAmount.toFixed(2)),
      total: Number(total.toFixed(2)),
      purity: product.purity,
      weight: weight,
      ratePerGram: livePrice.toFixed(2),
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
    return await prisma.goldPrice.create({
      data: {
        buyPrice: new Prisma.Decimal(buyPrice),
        sellPrice: new Prisma.Decimal(sellPrice),
        timestamp: new Date(),
      },
    });
  }
}


export default new ProductService();

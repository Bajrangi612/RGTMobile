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
              where: { status: 'PENDING' }
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
      where: { id },
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
  }) {
    return await prisma.product.create({
      data: {
        ...data,
        weight: new Prisma.Decimal(data.weight),
      },
    });
  }

  /**
   * Get the latest gold price from the database
   */
  async getLatestGoldPrice(): Promise<GoldPrice | null> {
    return await prisma.goldPrice.findFirst({
      orderBy: { timestamp: "desc" },
    });
  }

  /**
   * Calculate the current price of a product including 3% GST
   * @param product The product object
   * @param livePrice The current gold price per gram
   * @returns object with breaking down of price
   */
  calculateEffectivePrice(product: Product, livePrice: number) {
    const weight = Number(product.weight);
    const goldValue = weight * livePrice;
    
    // 3% GST
    const gstAmount = goldValue * 0.03;
    const total = goldValue + gstAmount;

    return {
      goldValue: Number(goldValue.toFixed(2)),
      gstAmount: Number(gstAmount.toFixed(2)),
      total: Number(total.toFixed(2)),
      purity: product.purity,
      weight: weight,
    };
  }
}

export default new ProductService();

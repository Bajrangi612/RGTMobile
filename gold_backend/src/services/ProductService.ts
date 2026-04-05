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

    return await prisma.Product.findMany({
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
    return await prisma.Product.findUnique({
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
    return await prisma.Product.create({
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

    return await prisma.Product.update({
      where: { id },
      data: updateData,
    });
  }

  /**
   * Delete a product (Soft delete by setting isActive to false)
   */
  async deleteProduct(id: string) {
    return await prisma.Product.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /**
   * Get the latest gold price from the database
   */
  async getLatestGoldPrice(): Promise<GoldPrice | null> {
    return await prisma.GoldPrice.findFirst({
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
    const makingCharges = Number(product.makingCharges || 0);
    const fixedPrice = Number(product.fixedPrice || 0);

    let goldValue: number;
    
    if (fixedPrice > 0) {
      goldValue = fixedPrice;
    } else {
      goldValue = (weight * livePrice) + makingCharges;
    }
    
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

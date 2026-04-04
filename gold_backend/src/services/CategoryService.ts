import { prisma } from "../lib/prisma";

class CategoryService {
  /**
   * Get all active categories
   */
  async getAllCategories() {
    return await prisma.category.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  /**
   * Get category by ID
   */
  async getCategoryById(id: string) {
    return await prisma.category.findUnique({
      where: { id },
    });
  }

  /**
   * Create a new category (Admin)
   */
  async createCategory(data: { name: string; slug: string; imageUrl?: string }) {
    return await prisma.category.create({
      data,
    });
  }
}

export default new CategoryService();

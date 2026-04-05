import { prisma } from "../lib/prisma";

class CategoryService {
  /**
   * Get all active categories
   */
  async getAllCategories() {
    return await prisma.Category.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  /**
   * Get category by ID
   */
  async getCategoryById(id: string) {
    return await prisma.Category.findUnique({
      where: { id },
    });
  }

  /**
   * Create a new category (Admin)
   */
  async createCategory(data: { name: string; slug: string; imageUrl?: string }) {
    return await prisma.Category.create({
      data,
    });
  }

  /**
   * Delete a category
   */
  async deleteCategory(id: string) {
    return await prisma.Category.update({
      where: { id },
      data: { isActive: false },
    });
  }
}

export default new CategoryService();

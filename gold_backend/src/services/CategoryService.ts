import { prisma } from "../lib/prisma";

class CategoryService {
  /**
   * Get categories with optional inactive inclusion
   */
  async getAllCategories(includeInactive: boolean = false) {
    const where = includeInactive ? {} : { isActive: true };
    return await prisma.category.findMany({
      where,
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

  /**
   * Soft delete a category
   */
  async deleteCategory(id: string) {
    return await prisma.category.update({
      where: { id },
      data: { isActive: false },
    });
  }
}

export default new CategoryService();

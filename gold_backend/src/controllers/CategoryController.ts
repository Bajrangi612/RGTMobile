import { Request, Response, NextFunction } from "express";
import CategoryService from "../services/CategoryService";
import { successResponse, errorResponse } from "../utils/response";

export class CategoryController {
  /**
   * Get all active categories (with optional inactive for Admins)
   */
  static async listCategories(req: any, res: Response, next: NextFunction) {
    try {
      const includeInactive = req.query.includeInactive === 'true' || req.user?.role === 'ADMIN';
      const categories = await CategoryService.getAllCategories(includeInactive);
      return successResponse(res, { categories }, "Categories fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create a new category (Admin)
   */
  static async createCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, slug, imageUrl } = req.body;
      
      if (!name || !slug) {
        return errorResponse(res, "Name and Slug are required", 400);
      }

      const category = await CategoryService.createCategory({
        name,
        slug,
        imageUrl,
      });

      return successResponse(res, { category }, "Category created successfully", 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete a category (Admin)
   */
  static async deleteCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id as string;
      await CategoryService.deleteCategory(id);
      return successResponse(res, null, "Category deleted successfully");
    } catch (error) {
      next(error);
    }
  }
}

import { Request, Response, NextFunction } from "express";
import CategoryService from "../services/CategoryService";
import { successResponse, errorResponse } from "../utils/response";

export class CategoryController {
  /**
   * Get all active categories
   */
  static async listCategories(req: Request, res: Response, next: NextFunction) {
    try {
      const categories = await CategoryService.getAllCategories();
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
}

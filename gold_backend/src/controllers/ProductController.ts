import { Request, Response, NextFunction } from "express";
import ProductService from "../services/ProductService";
import { successResponse, errorResponse } from "../utils/response";

export class ProductController {
  /**
   * Get all active gold coins
   */
  static async listProducts(req: Request, res: Response, next: NextFunction) {
    try {
      const { categoryId } = req.query;
      const products = await ProductService.getAllProducts(categoryId as string);
      const livePriceObj = await ProductService.getLatestGoldPrice();
      
      const livePrice = livePriceObj ? Number(livePriceObj.sellPrice) : 0;

      // Map products with current dynamic pricing
      const productsWithPrice = products.map((p: any) => {
        const productPojo = JSON.parse(JSON.stringify(p));
        return {
          ...productPojo,
          pricing: ProductService.calculateEffectivePrice(p as any, livePrice)
        };
      });

      return successResponse(res, { products: productsWithPrice, livePrice }, "Products fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get latest gold price specifically
   */
  static async getGoldPrice(req: Request, res: Response, next: NextFunction) {
    try {
      const livePriceObj = await ProductService.getLatestGoldPrice();
      const livePrice = livePriceObj ? Number(livePriceObj.sellPrice) : 0;
      const buyPrice = livePriceObj ? Number(livePriceObj.buyPrice) : 0;

      return successResponse(res, { livePrice, buyPrice }, "Latest gold price fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get product by ID with precise pricing
   */
  static async getProduct(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const product = await ProductService.getProductById(id as string);
      
      if (!product) return errorResponse(res, "Product not found", 404);

      const livePriceObj = await ProductService.getLatestGoldPrice();
      const livePrice = livePriceObj ? Number(livePriceObj.sellPrice) : 0;
      
      const pricing = ProductService.calculateEffectivePrice(product, livePrice);

      return successResponse(res, { product, pricing }, "Product details fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create a new gold coin (Admin only)
   */
  static async createProduct(req: Request, res: Response, next: NextFunction) {
    try {
      const { 
        name, description, weight, purity, stock, imageUrl, categoryId,
        makingCharges, fixedPrice 
      } = req.body;
      
      if (!name || !weight) {
        return errorResponse(res, "Name and Weight are required", 400);
      }
      
      const product = await ProductService.createProduct({
        name,
        description,
        weight: Number(weight),
        purity: purity || "24K",
        stock: Number(stock) || 0,
        imageUrl,
        categoryId,
        makingCharges: Number(makingCharges) || 0,
        fixedPrice: Number(fixedPrice) || 0,
      });

      return successResponse(res, { product }, "Product created successfully", 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update an existing gold coin (Admin only)
   */
  static async updateProduct(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id as string;
      const product = await ProductService.updateProduct(id, req.body);
      return successResponse(res, { product }, "Product updated successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete a gold coin (Admin only)
   */
  static async deleteProduct(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id as string;
      await ProductService.deleteProduct(id);
      return successResponse(res, null, "Product deleted successfully");
    } catch (error) {
      next(error);
    }
  }
  /**
   * Update gold price (Admin only)
   */
  static async updateGoldPrice(req: Request, res: Response, next: NextFunction) {
    try {
      const { buyPrice, sellPrice } = req.body;
      
      if (buyPrice === undefined || sellPrice === undefined) {
        return errorResponse(res, "Buy price and Sell price are required", 400);
      }

      await ProductService.updateGoldPrice(Number(buyPrice), Number(sellPrice));

      return successResponse(res, null, "Gold price updated successfully");
    } catch (error) {
      next(error);
    }
  }
}


import { Request, Response, NextFunction } from "express";
import R2Service from "../services/R2Service";
import { successResponse, errorResponse } from "../utils/response";
import { v4 as uuidv4 } from "uuid";

export class ImageController {
  /**
   * Upload an image to Cloudflare R2
   */
  static async uploadImage(req: Request, res: Response, next: NextFunction) {
    try {
      const file = req.file;

      if (!file) {
        return errorResponse(res, "No file uploaded", 400);
      }

      // Generate a unique filename
      const extension = file.originalname.split(".").pop();
      const fileName = `uploads/${uuidv4()}.${extension}`;

      // Upload to R2
      const publicUrl = await R2Service.uploadFile(
        file.buffer,
        fileName,
        file.mimetype
      );

      return successResponse(res, { url: publicUrl, key: fileName }, "Image uploaded successfully");
    } catch (error) {
      next(error);
    }
  }
}

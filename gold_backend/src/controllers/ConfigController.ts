import { Request, Response, NextFunction } from "express";
import { successResponse } from "../utils/response";

export class ConfigController {
  // Mock config storage for now (could be moved to DB later)
  static systemConfig = {
    commissionRate: 2.5,
    deliveryTimeDays: 5,
    orderIntervalMinutes: 15,
    gstRate: 3.0,
    minWithdrawal: 500,
  };

  /**
   * Get system configurations (Admin only)
   */
  static async getConfigs(req: Request, res: Response, next: NextFunction) {
    try {
      return successResponse(res, ConfigController.systemConfig, "Configs fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update system configurations (Admin only)
   */
  static async updateConfigs(req: Request, res: Response, next: NextFunction) {
    try {
      const updates = req.body;
      ConfigController.systemConfig = { ...ConfigController.systemConfig, ...updates };
      return successResponse(res, ConfigController.systemConfig, "Configs updated successfully");
    } catch (error) {
      next(error);
    }
  }
}

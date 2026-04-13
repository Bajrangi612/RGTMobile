import { Request, Response, NextFunction } from "express";
import { successResponse } from "../utils/response";
import { prisma } from "../lib/prisma";

export class ConfigController {
  /**
   * Get all system configurations (Admin only)
   */
  static async getConfigs(req: Request, res: Response, next: NextFunction) {
    try {
      const settings = await prisma.setting.findMany();
      // Map to a more usable object
      const config: any = {};
      settings.forEach((s) => {
        // Try to parse numbers or booleans
        let val: any = s.value;
        if (!isNaN(val as any)) val = Number(val);
        if (val === "true") val = true;
        if (val === "false") val = false;
        
        config[s.key] = val;
      });

      return successResponse(res, config, "Configs fetched successfully from DB");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get public system configurations (Public/User)
   */
  static async getPublicConfigs(req: Request, res: Response, next: NextFunction) {
    try {
      const settings = await prisma.setting.findMany({
        where: {
          key: {
            in: ["referral_reward", "min_withdrawal", "gst_rate", "delivery_days", "global_discount_percent"]
          }
        }
      });

      const config: any = {};
      settings.forEach((s) => {
        let val: any = s.value;
        if (!isNaN(val as any)) val = Number(val);
        config[s.key] = val;
      });

      return successResponse(res, config, "Public configs fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update or create system configurations (Admin only)
   */
  static async updateConfigs(req: Request, res: Response, next: NextFunction) {
    try {
      const updates = req.body;
      
      const updatePromises = Object.entries(updates).map(([key, value]) => {
        return prisma.setting.upsert({
          where: { key: key },
          update: { value: String(value) },
          create: {
            key: key,
            value: String(value),
          },
        });
      });

      await Promise.all(updatePromises);
      
      return successResponse(res, updates, "Configs updated in database successfully");
    } catch (error) {
      next(error);
    }
  }
}

import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";
import { Prisma } from "@prisma/client";

export class AdminController {
  /**
   * Update the global gold price (Buy/Sell)
   */
  static async updateGoldPrice(req: Request, res: Response, next: NextFunction) {
    try {
      const { buyPrice, sellPrice } = req.body;

      if (!buyPrice || !sellPrice) {
        return errorResponse(res, "Both buyPrice and sellPrice are required", 400);
      }

      const newPrice = await prisma.goldPrice.create({
        data: {
          buyPrice: new Prisma.Decimal(buyPrice),
          sellPrice: new Prisma.Decimal(sellPrice),
        },
      });

      return successResponse(res, newPrice, "Gold price updated successfully", 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get basic dashboard statistics
   */
  static async getDashboardStats(req: Request, res: Response, next: NextFunction) {
    try {
      const userCount = await prisma.user.count();
      const orderCount = await prisma.order.count({ where: { status: "PAID" } });
      const totalVolume = await prisma.order.aggregate({
        where: { status: "PAID" },
        _sum: { total: true }
      });

      const stats = {
        totalUsers: userCount,
        totalPaidOrders: orderCount,
        totalRevenue: totalVolume._sum.total || 0,
      };

      return successResponse(res, stats, "Dashboard stats fetched successfully");
    } catch (error) {
      next(error);
    }
  }
}

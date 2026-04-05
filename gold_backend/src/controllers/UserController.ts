import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";

export class UserController {
  /**
   * List all users (Admin only)
   */
  static async listAllUsers(req: Request, res: Response, next: NextFunction) {
    try {
      const users = await prisma.User.findMany({
        select: {
          id: true,
          name: true,
          phone: true,
          email: true,
          role: true,
          kycStatus: true,
          createdAt: true,
        },
        orderBy: { createdAt: "desc" },
      });

      return successResponse(res, { users }, "Users fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get dashboard stats (Admin only)
   */
  static async getStats(req: Request, res: Response, next: NextFunction) {
    try {
      const [userCount, orderCount, totalSales, pendingOrders, totalWeight] = await Promise.all([
        prisma.User.count(),
        prisma.Order.count(),
        prisma.Order.aggregate({
          _sum: { total: true },
          where: { status: "PAID" }
        }),
        prisma.Order.count({ where: { status: "PENDING" } }),
        prisma.Order.aggregate({
          _sum: { weight: true },
          where: { status: "PAID" }
        })
      ]);

      return successResponse(res, {
        userCount,
        orderCount,
        pendingOrders,
        totalSales: Number(totalSales._sum.total || 0),
        totalWeight: Number(totalWeight?._sum?.weight || 0),
      }, "Stats fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Submit Aadhaar KYC (Customer)
   */
  static async submitKyc(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const { aadhaarNo } = req.body;

      if (!aadhaarNo || aadhaarNo.length !== 12) {
        return errorResponse(res, "A valid 12-digit Aadhaar number is required", 400);
      }

      const user = await prisma.User.update({
        where: { id: userId },
        data: { 
          aadharNo: aadhaarNo,
          kycStatus: "PENDING" 
        },
      });

      return successResponse(res, { user }, "KYC submitted successfully and is pending approval");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update user KYC status (Admin only)
   */
  static async updateKyc(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params as { id: string };
      const { status } = req.body;

      if (!["verified", "rejected", "pending"].includes(status)) {
        return errorResponse(res, "Invalid KYC status", 400);
      }

      const user = await prisma.User.update({
        where: { id },
        data: { kycStatus: status.toUpperCase() as any },
      });

      return successResponse(res, { user }, `KYC status updated to ${status}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update current user profile
   */
  static async updateProfile(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const { name, email } = req.body;

      const user = await prisma.User.update({
        where: { id: userId },
        data: { name, email },
      });

      return successResponse(res, { user }, "Profile updated successfully");
    } catch (error) {
      next(error);
    }
  }
}

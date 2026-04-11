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
      const [userCount, orderCount, financialTotals] = await Promise.all([
        prisma.user.count(),
        prisma.order.count({ where: { status: { notIn: ["PAYMENT_PENDING", "CANCELLED"] } } }),
        prisma.order.aggregate({
          where: { status: { notIn: ["PAYMENT_PENDING", "CANCELLED"] } },
          _sum: { total: true, amount: true, gst: true, weight: true }
        })
      ]);

      // 2. Weekly Revenue Breakdown (Daily Groups)
      const now = new Date();
      const dailyRevenue = [];
      
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        date.setHours(0, 0, 0, 0);
        
        const nextDate = new Date(date);
        nextDate.setDate(nextDate.getDate() + 1);

        const daySum = await prisma.order.aggregate({
          where: {
            createdAt: { gte: date, lt: nextDate },
            status: { in: ["ORDER_CONFIRMED", "PROCESSING", "QUALITY_CHECKING", "READY_FOR_PICKUP", "PICKED_UP"] }
          },
          _sum: { total: true }
        });

        dailyRevenue.push({
          date: date,
          amount: Number(daySum._sum.total || 0)
        });
      }

      // 3. Pickup Pending specifically
      const pickupPending = await prisma.order.count({
        where: { status: "READY_FOR_PICKUP" }
      });

      const stats = {
        totalUsers: userCount,
        totalPaidOrders: orderCount,
        totalRevenue: Number(financialTotals._sum.total || 0),
        totalGoldWeight: Number(financialTotals._sum.weight || 0),
        grossAmount: Number(financialTotals._sum.amount || 0),
        totalGst: Number(financialTotals._sum.gst || 0),
        pendingPickups: pickupPending,
        weeklyData: dailyRevenue // Corrected daily aggregate
      };

      return successResponse(res, stats, "Dashboard stats fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update product stock (Total or Ready Stock)
   */
  static async updateStock(req: Request, res: Response, next: NextFunction) {
    try {
      const { productId, stock, readyStock } = req.body;
      if (!productId) return errorResponse(res, "Product ID is required", 400);

      const updateData: any = {};
      if (stock !== undefined) updateData.stock = stock;
      if (readyStock !== undefined) updateData.readyStock = readyStock;

      const product = await prisma.product.update({
        where: { id: productId },
        data: updateData,
      });

      // If readyStock was updated, trigger FIFO auto-approval
      if (readyStock !== undefined && readyStock > 0) {
        const OrderService = require("../services/OrderService").default;
        await OrderService.autoApproveOrders(productId, readyStock);
      }

      return successResponse(res, { product }, "Stock updated and orders processed");
    } catch (error) {
      next(error);
    }
  }
  /**
   * Get all transactions in the system (Admin Only)
   */
  static async getAllTransactions(req: Request, res: Response, next: NextFunction) {
    try {
      const [transactions, orders] = await Promise.all([
        prisma.transaction.findMany({
          orderBy: { createdAt: "desc" },
          include: { user: { select: { name: true, phone: true } } }
        }),
        prisma.order.findMany({
          orderBy: { createdAt: "desc" },
          include: { 
            user: { select: { name: true, phone: true } },
            product: { select: { name: true } }
          }
        })
      ]);

      // Normalize orders into transaction-like format
      const tableTxns = transactions.map(t => ({
        ...t,
        amount: Number(t.amount),
        user: t.user
      }));

      return successResponse(res, { transactions: tableTxns }, "All transactions fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update system settings (like delivery days)
   */
  static async updateSettings(req: Request, res: Response, next: NextFunction) {
    try {
      const updates = req.body;
      
      const updatePromises = Object.entries(updates).map(([key, value]) => {
        if (value === undefined) return null;
        return prisma.setting.upsert({
          where: { key: key },
          update: { value: String(value) },
          create: {
            key: key,
            value: String(value),
          },
        });
      }).filter(p => p !== null);

      await Promise.all(updatePromises);

      return successResponse(res, null, "Settings updated successfully");
    } catch (error) {
      next(error);
    }
  }
}

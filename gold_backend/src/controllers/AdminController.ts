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
      const orderCount = await prisma.order.count({ where: { status: "PAYMENT_SUCCESSFUL" } });
      const totalVolume = await prisma.order.aggregate({
        where: { status: "PAYMENT_SUCCESSFUL" },
        _sum: { total: true }
      });

      const stats = {
        totalUsers: userCount,
        totalPaidOrders: orderCount,
        totalRevenue: Number(totalVolume._sum.total || 0),
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
      const orderTxns = orders.map(o => ({
        id: o.id,
        userId: o.userId,
        type: "PURCHASE",
        amount: Number(o.total),
        description: `Order Purchase - ${o.product?.name || 'Gold Item'} (Qty: ${o.quantity})`,
        status: o.status,
        invoiceNo: o.invoiceNo,
        createdAt: o.createdAt,
        user: o.user
      }));

      const tableTxns = transactions.map(t => ({
        ...t,
        amount: Number(t.amount),
        user: t.user
      }));

      // Combine and Sort
      const combined = [...tableTxns, ...orderTxns].sort(
        (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      );

      return successResponse(res, { transactions: combined }, "All transactions fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update system settings (like delivery days)
   */
  static async updateSettings(req: Request, res: Response, next: NextFunction) {
    try {
      const { delivery_days } = req.body;
      
      if (delivery_days !== undefined) {
        await prisma.setting.upsert({
          where: { key: "delivery_days" },
          update: { value: delivery_days.toString() },
          create: { key: "delivery_days", value: delivery_days.toString() }
        });
      }

      return successResponse(res, null, "Settings updated successfully");
    } catch (error) {
      next(error);
    }
  }
}

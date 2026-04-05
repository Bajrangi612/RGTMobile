import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";

export class WalletController {
  /**
   * Get wallet balance and transactions
   */
  static async getWalletDetails(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const wallet = await prisma.wallet.findUnique({
        where: { userId },
      });

      const transactions = await prisma.transaction.findMany({
        where: { userId },
        orderBy: { createdAt: "desc" },
        take: 20,
      });

      return successResponse(res, { wallet, transactions }, "Wallet data fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Request withdrawal (Referral Rewards)
   */
  static async requestWithdrawal(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const { amount, type } = req.body; // type: 'REFERRAL' or 'WALLET'

      if (!amount || amount <= 0) {
        return errorResponse(res, "Invalid withdrawal amount", 400);
      }

      const wallet = await prisma.wallet.findUnique({ where: { userId } });
      if (!wallet) return errorResponse(res, "Wallet not found", 404);

      const year = new Date().getFullYear();
      const wdrCount = await prisma.transaction.count({
        where: { 
          type: "WITHDRAWAL",
          createdAt: { gte: new Date(`${year}-01-01`) } 
        }
      });
      const invoiceNo = `WDR/${year}/${(wdrCount + 1).toString().padStart(4, '0')}`;

      // 1. Create a PENDING withdrawal transaction
      const transaction = await prisma.transaction.create({
        data: {
          userId,
          type: "WITHDRAWAL",
          amount: amount,
          status: "PENDING",
          description: `Withdrawal request for ${type}`,
          invoiceNo: invoiceNo,
        } as any,
      });

      // 2. Note: We don't deduct yet. Deduct only after Admin approval.
      // Or we can deduct and keep in a 'HELD' state. 
      // For simplicity, let's just record the request.

      return successResponse(res, { transaction }, "Withdrawal request submitted");
    } catch (error) {
      next(error);
    }
  }
}

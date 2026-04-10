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
      console.log(`💰 [WalletController] Fetching wallet for user: ${userId}`);

      const [wallet, transactions, orders] = await Promise.all([
        prisma.wallet.findUnique({ where: { userId } }),
        prisma.transaction.findMany({ 
          where: { userId }, 
          orderBy: { createdAt: "desc" },
          take: 40 
        }),
        prisma.order.findMany({
          where: { userId, status: { in: ["PAYMENT_PENDING", "PAYMENT_SUCCESSFUL", "ORDER_CONFIRMED", "PROCESSING", "QUALITY_CHECKING", "READY_FOR_PICKUP", "PICKED_UP", "BUYBACK", "CANCELLED", "REFUNDED"] } },
          orderBy: { createdAt: "desc" },
          include: { product: true },
          take: 40
        })
      ]);

      // Normalize Transactions from table
      const tableTxns = transactions.map(t => ({
        id: t.id,
        userId: t.userId,
        type: t.type,
        amount: Number(t.amount),
        description: t.description,
        status: t.status,
        invoiceNo: t.invoiceNo,
        createdAt: t.createdAt.toISOString()
      }));

      // Normalize Orders to Transactions
      const existingInvoices = new Set(tableTxns.map(t => t.invoiceNo).filter(Boolean));
      
      const orderTxns = orders
        .filter(o => !existingInvoices.has(o.invoiceNo))
        .map(order => ({
          id: order.id,
          userId: order.userId,
          type: "PURCHASE",
          amount: Number(order.total),
          description: `Gold Purchase - ${(order as any).product?.name || 'Gold'} (Qty: ${order.quantity})`,
          status: order.status === "PAYMENT_SUCCESSFUL" ? "COMPLETED" : order.status,
          invoiceNo: order.invoiceNo,
          createdAt: order.createdAt.toISOString()
        }));

      // Combine and sort
      const combined = [...tableTxns, ...orderTxns]
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, 40);

      return successResponse(res, { wallet, transactions: combined }, "Wallet data fetched");
    } catch (error) {
      console.error("❌ [WalletController] Error:", error);
      next(error);
    }
  }

  /**
   * Request withdrawal (Secured with dynamic thresholds)
   */
  static async requestWithdrawal(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const { amount, type } = req.body; // type: 'REFERRAL' or 'WALLET'
      const requestedAmount = Number(amount);

      if (!requestedAmount || requestedAmount <= 0) {
        return errorResponse(res, "Invalid withdrawal amount", 400);
      }

      // 1. Enforce Dynamic Minimum Withdrawal Threshold
      const minWithdrawalSetting = await prisma.setting.findUnique({ where: { key: "min_withdrawal" } });
      const minAmount = minWithdrawalSetting ? Number(minWithdrawalSetting.value) : 1000;

      if (requestedAmount < minAmount) {
        return errorResponse(res, `Minimum withdrawal amount is ₹${minAmount}`, 400);
      }

      const wallet = await prisma.wallet.findUnique({ where: { userId } });
      if (!wallet) return errorResponse(res, "Wallet not found", 404);

      // 2. Strict Balance Verification
      if (type === 'REFERRAL') {
        const referralRewards = Number(wallet.referralRewards);
        if (requestedAmount > referralRewards) {
          return errorResponse(res, `Insufficient referral rewards balance (Available: ₹${referralRewards})`, 400);
        }
      } else {
        const mainBalance = Number(wallet.balance);
        if (requestedAmount > mainBalance) {
          return errorResponse(res, `Insufficient wallet balance (Available: ₹${mainBalance})`, 400);
        }
      }

      const year = new Date().getFullYear();
      const wdrCount = await prisma.transaction.count({
        where: { 
          type: "WITHDRAWAL",
          createdAt: { gte: new Date(`${year}-01-01`) } 
        }
      });
      const invoiceNo = `WDR/${year}/${(wdrCount + 1).toString().padStart(4, '0')}`;

      // 3. Create a PENDING withdrawal transaction
      const transaction = await prisma.transaction.create({
        data: {
          userId,
          type: "WITHDRAWAL",
          amount: requestedAmount,
          status: "PENDING",
          description: `Withdrawal request for ${type}`,
          invoiceNo: invoiceNo,
        } as any,
      });

      return successResponse(res, { transaction }, "Withdrawal request submitted successfully");
    } catch (error) {
      next(error);
    }
  }
}

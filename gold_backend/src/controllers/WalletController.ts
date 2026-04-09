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
          where: { userId, status: { in: ["CREATED", "PAID", "PENDING", "READY", "PICKED", "RESOLD", "CANCELLED", "REFUND_REQUESTED", "REFUNDED"] } },
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

      // Normalize Orders to Transactions (only if they don't have a record in the transaction table yet)
      // We check by invoiceNo
      const existingInvoices = new Set(tableTxns.map(t => t.invoiceNo).filter(Boolean));
      
      const orderTxns = orders
        .filter(o => !existingInvoices.has(o.invoiceNo))
        .map(order => ({
          id: order.id,
          userId: order.userId,
          type: "PURCHASE",
          amount: Number(order.total),
          description: `Gold Purchase - ${order.product?.name || 'Gold'} (Qty: ${order.quantity})`,
          status: order.status === "PAID" ? "COMPLETED" : order.status,
          invoiceNo: order.invoiceNo,
          createdAt: order.createdAt.toISOString()
        }));

      // Combine and sort
      const combined = [...tableTxns, ...orderTxns]
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, 40);

      console.log(`✅ [WalletController] Returning ${combined.length} transactions`);

      return successResponse(res, { wallet, transactions: combined }, "Wallet data fetched");
    } catch (error) {
      console.error("❌ [WalletController] Error:", error);
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

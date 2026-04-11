import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";

export class WithdrawalController {
  /**
   * Request a withdrawal (User)
   */
  static async requestWithdrawal(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user!.id as string;
      const { amount, bankDetails } = req.body;

      if (!amount || amount <= 0) {
        return errorResponse(res, "Invalid amount", 400);
      }

      // Check user balance (assuming wallet is linked)
      const user = await prisma.user.findUnique({
        where: { id: userId },
        include: { wallet: true }
      });

      if (!user || !user.wallet || Number(user.wallet.balance) < amount) {
        return errorResponse(res, "Insufficient balance", 400);
      }

      const request = await prisma.$transaction(async (tx) => {
        const newRequest = await tx.withdrawalRequest.create({
          data: {
            userId,
            amount,
            bankDetails: bankDetails || {
              accNo: user.bankAccountNo,
              holderName: user.bankHolderName,
              ifsc: user.bankIfsc,
              bankName: user.bankName
            },
            status: "PENDING"
          }
        });

        // Deduct immediately to prevent double spending
        await tx.wallet.update({
          where: { userId },
          data: { balance: { decrement: amount } }
        });

        return newRequest;
      });

      return successResponse(res, { request }, "Withdrawal request raised successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all withdrawals for current user
   */
  static async myWithdrawals(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user!.id as string;
      const { page, limit } = req.query;
      const pageNum = parseInt(page as string) || 1;
      const limitNum = parseInt(limit as string) || 50;
      const skip = (pageNum - 1) * limitNum;

      const [requestsData, total] = await Promise.all([
        prisma.withdrawalRequest.findMany({
          where: { userId },
          orderBy: { createdAt: "desc" },
          skip,
          take: limitNum
        }),
        prisma.withdrawalRequest.count({ where: { userId } })
      ]);

      const requests = requestsData.map(r => ({
        ...r,
        amount: Number(r.amount)
      }));

      return successResponse(res, { 
        requests,
        pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) }
      }, "My withdrawal requests fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all withdrawals (Admin)
   */
  static async listWithdrawals(req: Request, res: Response, next: NextFunction) {
    try {
      const { page, limit } = req.query;
      const pageNum = parseInt(page as string) || 1;
      const limitNum = parseInt(limit as string) || 50;
      const skip = (pageNum - 1) * limitNum;

      const [requestsData, total] = await Promise.all([
        prisma.withdrawalRequest.findMany({
          include: { user: { select: { name: true, phone: true } } },
          orderBy: { createdAt: "desc" },
          skip,
          take: limitNum
        }),
        prisma.withdrawalRequest.count()
      ]);

      const requests = requestsData.map(r => ({
        ...r,
        amount: Number(r.amount)
      }));

      return successResponse(res, { 
        requests,
        pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) }
      }, "Withdrawal requests fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update withdrawal status (Admin)
   */
  static async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { status, adminNotes } = req.body;

      const request = await prisma.withdrawalRequest.findUnique({
        where: { id: id as string },
        include: { user: { include: { wallet: true } } }
      });

      if (!request) return errorResponse(res, "Request not found", 404);

      // If approved/completed, we log the transaction since balance is already deducted
      if (status === "COMPLETED" && request.status !== "COMPLETED") {
        await prisma.$transaction(async (tx) => {
          await tx.withdrawalRequest.update({
            where: { id: id as string },
            data: { status, adminNotes: adminNotes as string }
          });

          // Create transaction record
          await tx.transaction.create({
            data: {
              userId: request.userId,
              type: "WITHDRAWAL",
              amount: request.amount,
              description: `Withdrawal successfully processed to bank account.`,
              status: "COMPLETED"
            }
          });
        });
      } else if (status === "REJECTED" && request.status !== "REJECTED") {
         // If rejected, refund the balance back to the wallet
         await prisma.$transaction(async (tx) => {
          await tx.withdrawalRequest.update({
            where: { id: id as string },
            data: { status, adminNotes: adminNotes as string }
          });

          if (request.user.wallet) {
            await tx.wallet.update({
              where: { id: (request.user as any).wallet.id },
              data: { balance: { increment: request.amount } }
            });
            
            await tx.transaction.create({
              data: {
                userId: request.userId,
                type: "CREDIT",
                amount: request.amount,
                description: `Refund for rejected withdrawal. ${adminNotes || ''}`,
                status: "COMPLETED"
              }
            });
          }
         });
      } else {
        await prisma.withdrawalRequest.update({
          where: { id: id as string },
          data: { status, adminNotes: adminNotes as string }
        });
      }

      return successResponse(res, {}, `Withdrawal status updated to ${status}`);
    } catch (error) {
      next(error);
    }
  }
}

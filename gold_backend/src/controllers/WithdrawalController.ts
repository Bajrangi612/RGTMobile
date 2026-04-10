import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";

export class WithdrawalController {
  /**
   * Request a withdrawal (User)
   */
  static async requestWithdrawal(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id as string;
      const { amount, bankDetails } = req.body;

      if (!amount || amount <= 0) {
        return errorResponse(res, "Invalid amount", 400);
      }

      // Check user balance (assuming wallet is linked)
      const user = await prisma.user.findUnique({
        where: { id: userId },
        include: { wallet: true }
      });

      if (!user || (user.wallet && user.wallet.balance < amount)) {
        return errorResponse(res, "Insufficient balance", 400);
      }

      const request = await prisma.withdrawalRequest.create({
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

      return successResponse(res, { request }, "Withdrawal request raised successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all withdrawals (Admin)
   */
  static async listWithdrawals(req: Request, res: Response, next: NextFunction) {
    try {
      const requests = await prisma.withdrawalRequest.findMany({
        include: { user: { select: { name: true, phone: true } } },
        orderBy: { createdAt: "desc" }
      });

      return successResponse(res, { requests }, "Withdrawal requests fetched successfully");
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
        where: { id },
        include: { user: { include: { wallet: true } } }
      });

      if (!request) return errorResponse(res, "Request not found", 404);

      // If approved/completed, we should deduct from user wallet in a transaction
      if (status === "COMPLETED" && request.status !== "COMPLETED") {
        await prisma.$transaction(async (tx) => {
          await tx.withdrawalRequest.update({
            where: { id },
            data: { status, adminNotes }
          });

          if (request.user.wallet) {
            await tx.wallet.update({
              where: { id: request.user.wallet.id },
              data: { balance: { decrement: request.amount } }
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
          }
        });
      } else {
        await prisma.withdrawalRequest.update({
          where: { id },
          data: { status, adminNotes }
        });
      }

      return successResponse(res, {}, `Withdrawal status updated to ${status}`);
    } catch (error) {
      next(error);
    }
  }
}

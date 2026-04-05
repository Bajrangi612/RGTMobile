import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";

export class BankController {
  /**
   * Submit bank details (Customer)
   */
  static async submitBankDetails(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const { accountNumber, ifscCode, accountHolderName, bankName } = req.body;

      if (!accountNumber || !ifscCode || !accountHolderName) {
        return errorResponse(res, "Account number, IFSC, and Holder name are required", 400);
      }

      const user = await prisma.user.update({
        where: { id: userId },
        data: {
          bankAccountNo: accountNumber,
          bankIfsc: ifscCode,
          bankHolderName: accountHolderName,
          bankName: bankName || "Unknown Bank",
          bankStatus: "PENDING",
        } as any,
      }) as any;

      return successResponse(res, { user }, "Bank details submitted for verification");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get current user's bank details
   */
  static async getBankDetails(req: any, res: Response, next: NextFunction) {
    try {
      const userId = req.user.id;
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          bankAccountNo: true,
          bankIfsc: true,
          bankHolderName: true,
          bankName: true,
          bankStatus: true,
        } as any,
      }) as any;

      return successResponse(res, { bank: user }, "Bank details fetched");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update bank status (Admin only)
   */
  static async updateBankStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.params.userId as string;
      const { status } = req.body;

      if (!["VERIFIED", "REJECTED", "PENDING"].includes(status)) {
        return errorResponse(res, "Invalid status", 400);
      }

      const user = await prisma.user.update({
        where: { id: userId },
        data: { bankStatus: status as any } as any,
      }) as any;

      return successResponse(res, { user }, `Bank status updated to ${status}`);
    } catch (error) {
      next(error);
    }
  }
}

import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/AuthService';
import { UserService } from '../services/UserService';
import { prisma } from '../lib/prisma';
import { successResponse, errorResponse } from '../utils/response';

export class AuthController {
  static async me(req: any, res: Response, next: NextFunction) {
    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user.id }
      });
      if (!user) return errorResponse(res, 'User not found', 404);
      
      return successResponse(
        res,
        {
          user: {
            id: user.id,
            name: user.name,
            phone: user.phone,
            contactNo: user.phone, // Legacy compatibility
            email: user.email,
            role: user.role,
            goldAdvanceAmount: 0, // Legacy compatibility
            referralCode: "", // Legacy compatibility
            registerRequired: false,
          }
        },
        'User fetched successfully'
      );
    } catch (error) {
      next(error);
    }
  }

  static async sendOtp(req: Request, res: Response, next: NextFunction) {
    try {
      const phone = req.body.phone || req.body.mobile;
      if (!phone) return errorResponse(res, 'Phone/Mobile number is required', 400);

      const mockCode = await AuthService.sendOtp(phone);
      return successResponse(res, { mockCode }, 'OTP sent successfully');
    } catch (error) {
      next(error);
    }
  }

  static async verifyOtp(req: Request, res: Response, next: NextFunction) {
    try {
      const phone = req.body.phone || req.body.mobile;
      const code = req.body.code || req.body.otp;
      
      if (!phone || !code) return errorResponse(res, 'Phone and OTP are required', 400);

      const { user: existingUser, phone: normalizedPhone } = await AuthService.verifyOtp(phone, code);

      let user: any = existingUser;
      let isNewUser = false;

      // Auto-onboarding (Silent Registration)
      if (!user) {
        user = await UserService.createCustomer({
          name: `User ${normalizedPhone}`,
          phone: normalizedPhone,
          email: `${normalizedPhone}@royalgold.app`,
        });
        isNewUser = true;
      }

      const token = AuthService.generateToken(user.id, user.role);

      return successResponse(
        res,
        {
          token,
          user: {
            id: user.id,
            name: user.name,
            phone: user.phone,
            contactNo: user.phone, // Legacy compatibility
            email: user.email,
            role: user.role,
            goldAdvanceAmount: 0, // Legacy compatibility
            referralCode: "", // Legacy compatibility
            registerRequired: isNewUser,
          },
        },
        isNewUser ? 'Account created and logged in' : 'Login successful'
      );
    } catch (error) {
      next(error);
    }
  }
}

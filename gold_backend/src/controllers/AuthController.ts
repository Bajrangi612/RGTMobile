import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/AuthService';
import { UserService } from '../services/UserService';
import { prisma } from '../lib/prisma';
import { successResponse, errorResponse } from '../utils/response';

const otpRateLimit = new Map<string, { count: number, lastRequest: number }>();
const MAX_OTP_REQUESTS = 3;
const RATE_LIMIT_WINDOW = 5 * 60 * 1000; // 5 minutes

export class AuthController {
  static async me(req: any, res: Response, next: NextFunction) {
    try {
        const userData = await prisma.user.findUnique({
        where: { id: req.user.id },
        include: { 
          wallet: true,
          orders: {
            where: { status: { in: ["ORDER_CONFIRMED", "PROCESSING", "QUALITY_CHECKING", "READY_FOR_PICKUP", "PICKED_UP"] } },
            select: { total: true }
          },
          _count: {
            select: { orders: { where: { status: { notIn: ["PAYMENT_PENDING", "CANCELLED"] } } } }
          }
        }
      }) as any;
      
      if (!userData) return errorResponse(res, 'User not found', 404);
      
      const totalCollectionValue = userData.orders.reduce((sum: number, order: any) => sum + Number(order.total), 0);
      
      return successResponse(
        res,
        {
          user: {
            id: userData.id,
            name: userData.name,
            phone: userData.phone,
            contactNo: userData.phone,
            email: userData.email,
            role: userData.role,
            kycStatus: userData.kycStatus,
            bankStatus: userData.bankStatus,
            referralCode: userData.referralCode,
            address: userData.address,
            dob: userData.dob,
            panNo: userData.panNo,
            aadharNo: userData.aadharNo,
            bankAccountNo: userData.bankAccountNo,
            bankIfsc: userData.bankIfsc,
            bankHolderName: userData.bankHolderName,
            bankName: userData.bankName,
            wallet: userData.wallet ? {
              balance: Number(userData.wallet.balance),
            } : null,
            totalCollectionValue: totalCollectionValue,
            orderCount: userData._count?.orders || 0,
            registerRequired: !userData.name || userData.name.startsWith('User '),
            isAdmin: userData.role === 'ADMIN',
            pin: userData.pin,
            pinUpdatedAt: userData.pinUpdatedAt,
            passKeySet: !!userData.pin,
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

      // Simple Rate Limiting
      const now = Date.now();
      const userLimit = otpRateLimit.get(phone);
      if (userLimit) {
        if (now - userLimit.lastRequest < RATE_LIMIT_WINDOW) {
          if (userLimit.count >= MAX_OTP_REQUESTS) {
            return errorResponse(res, `Too many OTP requests. Please wait ${Math.ceil((RATE_LIMIT_WINDOW - (now - userLimit.lastRequest)) / 1000 / 60)} minutes.`, 429);
          }
          userLimit.count++;
          userLimit.lastRequest = now;
        } else {
          otpRateLimit.set(phone, { count: 1, lastRequest: now });
        }
      } else {
        otpRateLimit.set(phone, { count: 1, lastRequest: now });
      }

      const mockCode = await AuthService.sendOtp(phone);
      
      return successResponse(
        res, 
        { 
          // Only return mockCode in non-production environments
          mockCode: process.env.NODE_ENV === 'production' ? undefined : mockCode 
        }, 
        'OTP sent successfully'
      );
    } catch (error) {
      next(error);
    }
  }

  static async adminLogin(req: Request, res: Response, next: NextFunction) {
    try {
      const { pin } = req.body;
      if (!pin) return errorResponse(res, 'PIN is required', 400);

      // In production, you'd fetch the admin user and check a hashed PIN.
      // For now, since the user explicitly uses '1234' in frontend,
      // we'll validate it against the seeded admin.
      const admin = await prisma.user.findFirst({
        where: { 
          role: 'ADMIN',
          phone: '9999999999' // Main Admin
        }
      });

      if (!admin || pin !== '1234') {
        return errorResponse(res, 'Invalid Admin PIN', 401);
      }

      const token = AuthService.generateToken(admin.id, admin.role);

      return successResponse(res, {
        token,
        user: {
          id: admin.id,
          name: admin.name,
          phone: admin.phone,
          role: admin.role,
          isAdmin: true,
        }
      }, 'Admin login successful');
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
            kycStatus: user.kycStatus,
            bankStatus: user.bankStatus,
            address: user.address,
            dob: user.dob,
            panNo: user.panNo,
            aadharNo: user.aadharNo,
            bankAccountNo: user.bankAccountNo,
            bankIfsc: user.bankIfsc,
            bankHolderName: user.bankHolderName,
            bankName: user.bankName,
            goldAdvanceAmount: 0, // Legacy compatibility
            referralCode: user.referralCode || "", 
            registerRequired: isNewUser,
            isAdmin: user.role === 'ADMIN',
            pin: user.pin,
            pinUpdatedAt: user.pinUpdatedAt,
            passKeySet: !!user.pin,
          },
        },

        isNewUser ? 'Account created and logged in' : 'Login successful'
      );
    } catch (error) {
      next(error);
    }
  }
}

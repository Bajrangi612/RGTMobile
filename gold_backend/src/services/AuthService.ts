import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma';
import { normalizeMobile } from '../utils/phone';

export class AuthService {
  static async sendOtp(rawPhone: string) {
    const phone = normalizeMobile(rawPhone);
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await prisma.Otp.upsert({
      where: { phone },
      update: { code, expiresAt, verified: false },
      create: { phone, code, expiresAt },
    });

    console.log(`[SMS MOCK] OTP for ${phone}: ${code}`);
    return code;
  }

  static async verifyOtp(rawPhone: string, code: string) {
    const phone = normalizeMobile(rawPhone);
    const otpRecord = await prisma.Otp.findUnique({ where: { phone } });

    if (!otpRecord || otpRecord.code !== code || otpRecord.expiresAt < new Date()) {
      throw new Error('Invalid or expired OTP');
    }

    await prisma.Otp.update({
      where: { phone },
      data: { verified: true },
    });

    const user = await prisma.User.findUnique({
      where: { phone },
      include: { wallet: true },
    });

    return { user, phone };
  }

  static generateToken(userId: string, role: string) {
    return jwt.sign(
      { id: userId, role },
      process.env.JWT_SECRET!,
      {
        expiresIn: (process.env.JWT_EXPIRES_IN || '7d') as any,
      }
    );
  }
}

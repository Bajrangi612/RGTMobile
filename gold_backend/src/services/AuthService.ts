import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma';
import { normalizeMobile } from '../utils/phone';

export class AuthService {
  static async sendOtp(rawPhone: string) {
    const phone = normalizeMobile(rawPhone);
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await prisma.otp.upsert({
      where: { phone },
      update: { code, expiresAt, verified: false },
      create: { phone, code, expiresAt },
    });

    console.log(`[OTP] Sending ${code} to ${phone}`);

    // Real SMS integration via 2Factor.in
    const apiKey = process.env.TWOFACTOR_API_KEY;
    if (apiKey) {
      try {
        const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phone}/${code}/OTP1`;
        const response = await fetch(url);
        const result = await response.json() as any;
        
        if (result.Status !== 'Success') {
          console.error(`❌ [2Factor] SMS delivery failed: ${result.Details}`);
        } else {
          console.log(`✅ [2Factor] SMS sent successfully: ${result.Details}`);
        }
      } catch (err) {
        console.error('❌ [2Factor] Network error during SMS delivery:', err);
      }
    } else {
      console.log('⚠️ [2Factor] API Key missing. Skipping real SMS delivery.');
    }

    // Always return code for consistency (or handled in controller)
    return code;
  }

  static async verifyOtp(rawPhone: string, code: string) {
    const phone = normalizeMobile(rawPhone);
    const otpRecord = await prisma.otp.findUnique({ where: { phone } });

    console.log(`[OTP] Verifying for ${phone}. Input: ${code}`);

    if (!otpRecord) {
      console.error(`❌ [OTP] No record found for ${phone}`);
      throw new Error('Invalid or expired OTP');
    }

    if (otpRecord.code !== code) {
      console.error(`❌ [OTP] Code mismatch for ${phone}. Expected ${otpRecord.code}, Got ${code}`);
      throw new Error('Invalid or expired OTP');
    }

    if (otpRecord.expiresAt < new Date()) {
      console.error(`❌ [OTP] Code expired for ${phone}. Expired at: ${otpRecord.expiresAt}`);
      throw new Error('Invalid or expired OTP');
    }

    console.log(`✅ [OTP] Verification successful for ${phone}`);

    await prisma.otp.update({
      where: { phone },
      data: { verified: true },
    });

    const user = await prisma.user.findUnique({
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

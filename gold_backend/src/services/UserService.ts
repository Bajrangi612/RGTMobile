import { prisma } from '../lib/prisma';
import { normalizeMobile } from '../utils/phone';
import bcrypt from 'bcryptjs';

export class UserService {
  static async createCustomer(data: {
    name: string;
    phone: string;
    email: string;
  }) {
    const phone = normalizeMobile(data.phone);

    return await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name: data.name,
          phone,
          email: data.email,
          password: Math.random().toString(36).slice(-8), // Dummy password
          role: 'CUSTOMER',
          referralCode: Math.random().toString(36).substring(2, 10).toUpperCase(),
        },
      });

      await tx.wallet.create({
        data: {
          userId: user.id,
          balance: 0,
        },
      });

      return user;
    });
  }

  static async getByPhone(phone: string) {
    return await prisma.user.findUnique({
      where: { phone: normalizeMobile(phone) },
      include: { wallet: true },
    });
  }

  static async setPin(userId: string, pin: string) {
    const hashedPin = await bcrypt.hash(pin, 10);
    return await prisma.user.update({
      where: { id: userId },
      data: { 
        pin: hashedPin,
        pinUpdatedAt: new Date()
      },
    });
  }

  static async verifyPin(userId: string, pin: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { pin: true },
    });
    if (!user || !user.pin) return false;
    return await bcrypt.compare(pin, user.pin);
  }
}


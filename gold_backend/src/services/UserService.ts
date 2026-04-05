import { prisma } from '../lib/prisma';
import { normalizeMobile } from '../utils/phone';

export class UserService {
  static async createCustomer(data: {
    name: string;
    phone: string;
    email: string;
  }) {
    const phone = normalizeMobile(data.phone);

    return await prisma.$transaction(async (tx) => {
      const user = await tx.User.create({
        data: {
          name: data.name,
          phone,
          email: data.email,
          password: Math.random().toString(36).slice(-8), // Dummy password
          role: 'CUSTOMER',
          referralCode: Math.random().toString(36).substring(2, 10).toUpperCase(),
        },
      });

      await tx.Wallet.create({
        data: {
          userId: user.id,
          balance: 0,
        },
      });

      return user;
    });
  }

  static async getByPhone(phone: string) {
    return await prisma.User.findUnique({
      where: { phone: normalizeMobile(phone) },
      include: { wallet: true },
    });
  }
}

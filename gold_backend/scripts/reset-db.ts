import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function reset() {
  console.log('🚮 Starting Database Reset (Preserving Products & Admin)...');

  try {
    // 1. Clear Activity Tables (Order of deletion matters for FK)
    console.log('📉 Clearing Transactions & History...');
    await prisma.orderStatusHistory.deleteMany();
    await prisma.buybackRequest.deleteMany();
    await prisma.payment.deleteMany();
    await prisma.withdrawalRequest.deleteMany();
    await prisma.transaction.deleteMany();
    await prisma.notification.deleteMany();
    await prisma.otp.deleteMany();
    await prisma.auditLog.deleteMany();

    // 2. Clear Orders
    console.log('📦 Clearing Orders...');
    await prisma.order.deleteMany();

    // 3. Handle Users & Wallets
    console.log('👤 Handling Users...');
    // Delete non-admin wallets first
    await prisma.wallet.deleteMany({
      where: {
        user: {
          role: { not: 'ADMIN' }
        }
      }
    });

    // Delete non-admin users
    const deleteUsers = await prisma.user.deleteMany({
      where: {
        role: { not: 'ADMIN' }
      }
    });
    console.log(`✅ Deleted ${deleteUsers.count} customer accounts.`);

    // Reset Admin Wallet
    await prisma.wallet.updateMany({
      data: { balance: 0 }
    });
    console.log('💰 Reset Admin wallet to 0.');

    console.log('\n✨ Database Cleanup Complete! Products and Admin are preserved.');
    console.log('🚀 You can now test the registration and order flow from scratch.');

  } catch (error) {
    console.error('❌ Error during reset:', error);
  } finally {
    await prisma.$disconnect();
  }
}

reset();

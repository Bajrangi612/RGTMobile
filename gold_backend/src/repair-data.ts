import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

/**
 * Obsidian Elite: Self-Healing Data Integrity Script
 * This script purges invalid empty strings and NULLs from enum columns
 * using RAW SQL to bypass Prisma's strict validation during repair.
 */
async function heal() {
  console.log('🛡️ [Integrity] Starting Data Healing sequence...');
  
  try {
    // 1. Repair Order Statuses
    console.log('📦 [Integrity] Purging invalid Order Statuses...');
    const orderFix = await prisma.$executeRawUnsafe(
      "UPDATE `order` SET status = 'CREATED' WHERE status = '' OR status IS NULL;"
    );
    console.log(`✅ [Integrity] Repaired ${orderFix} orders.`);

    // 2. Repair Transaction Types
    console.log('💰 [Integrity] Purging invalid Transaction Types...');
    const txnFix = await prisma.$executeRawUnsafe(
      "UPDATE `transaction` SET type = 'PURCHASE' WHERE type = '' OR type IS NULL;"
    );
    console.log(`✅ [Integrity] Repaired ${txnFix} transactions.`);

    console.log('✨ [Integrity] Data Healing complete.');
  } catch (error) {
    console.error('❌ [Integrity] Error during healing sequence:', error);
    // We don't exit with error here to ensure the server still tries to start
  } finally {
    await prisma.$disconnect();
  }
}

heal();

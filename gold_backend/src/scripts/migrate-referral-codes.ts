import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function migrate() {
  console.log('🚀 Starting Referral Code Migration...');
  
  const users = await prisma.user.findMany({
    select: { id: true, phone: true, referralCode: true, name: true }
  });

  console.log(`📊 Found ${users.length} users to process.`);

  let updatedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const user of users) {
    try {
      // Normalize to last 10 digits
      const normalizedPhone = user.phone.replace(/\D/g, '').slice(-10);
      
      if (user.referralCode === normalizedPhone) {
        skippedCount++;
        continue;
      }

      await prisma.user.update({
        where: { id: user.id },
        data: { referralCode: normalizedPhone }
      });

      console.log(`✅ Updated ${user.name} (${user.phone}) -> ${normalizedPhone}`);
      updatedCount++;
    } catch (err: any) {
      console.error(`❌ Failed to update user ${user.id}: ${err.message}`);
      errorCount++;
    }
  }

  console.log('\n✨ Migration Complete!');
  console.log(`✅ Updated: ${updatedCount}`);
  console.log(`⏩ Skipped: ${skippedCount}`);
  console.log(`❌ Errors: ${errorCount}`);
  
  await prisma.$disconnect();
}

migrate().catch(err => {
  console.error('💥 Critical Migration Error:', err);
  process.exit(1);
});

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- PRODUCTION SEED/SYNC ---');
  
  const settings = [
    { key: 'referral_reward', value: '500' },
    { key: 'delivery_days', value: '7' },
    { key: 'gst_rate', value: '3.0' },
  ];

  for (const s of settings) {
    const existing = await prisma.setting.findUnique({ where: { key: s.key } });
    if (!existing) {
      await prisma.setting.create({ data: s });
      console.log(`✅ Created setting: ${s.key} = ${s.value}`);
    } else {
      console.log(`ℹ️ Setting exists: ${s.key} = ${existing.value}`);
    }
  }

  console.log('--- COMPLETE ---');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

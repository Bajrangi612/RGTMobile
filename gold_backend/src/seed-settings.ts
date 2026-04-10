import { prisma } from './lib/prisma';

async function seed() {
  try {
    await prisma.setting.upsert({
      where: { key: 'delivery_days' },
      update: {},
      create: {
        key: 'delivery_days',
        value: '7',
        description: 'Standard delivery days after payment'
      }
    });

    await prisma.setting.upsert({
      where: { key: 'referral_reward' },
      update: {},
      create: {
        key: 'referral_reward',
        value: '500',
        description: 'Fixed reward for successful referrals'
      }
    });

    await prisma.setting.upsert({
      where: { key: 'min_withdrawal' },
      update: {},
      create: {
        key: 'min_withdrawal',
        value: '1000',
        description: 'Minimum balance required to request withdrawal'
      }
    });
    console.log('✅ Settings seeded successfully');
  } catch (error) {
    console.error('❌ Error seeding settings:', error);
  } finally {
    await prisma.$disconnect();
  }
}

seed();

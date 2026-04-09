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
    console.log('✅ Settings seeded successfully');
  } catch (error) {
    console.error('❌ Error seeding settings:', error);
  } finally {
    await prisma.$disconnect();
  }
}

seed();

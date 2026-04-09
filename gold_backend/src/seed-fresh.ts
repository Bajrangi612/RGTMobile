import { prisma } from './lib/prisma';
import { Prisma } from '@prisma/client';
import bcrypt from 'bcryptjs';

async function main() {
  console.log('🌱 Starting Seed...');

  // 1. Clear existing data (Done via db push --force-reset, but double safe)
  // Actually db push --force-reset already cleared it.

  // 2. Admin User
  const adminHashedPassword = await bcrypt.hash('admin-password-2026', 10);
  await prisma.user.upsert({
    where: { phone: '9999999999' },
    update: {},
    create: {
      name: 'Main Admin',
      phone: '9999999999',
      email: 'admin@royalgold.app',
      password: adminHashedPassword,
      role: 'ADMIN',
      referralCode: 'ADMIN777',
      wallet: {
        create: {
          balance: 0,
        }
      }
    },
  });
  console.log('✅ Admin user created');

  // 3. Settings
  const settings = [
    { key: 'delivery_days', value: '7', description: 'Default delivery countdown' },
  ];

  for (const s of settings) {
    await prisma.setting.upsert({
      where: { key: s.key },
      update: s,
      create: s,
    });
  }
  console.log('✅ Settings seeded');

  // 4. Categories
  const coinsCat = await prisma.category.upsert({
    where: { slug: 'gold-coins' },
    update: {},
    create: {
      name: 'Gold Coins',
      slug: 'gold-coins',
      imageUrl: 'https://pub-ee54ba2945a04c56b29b01ae5ec3c085.r2.dev/coins_cat.png'
    },
  });
  console.log('✅ Categories seeded');

  // 5. Products
  const products = [
    {
      name: '1g 24K Gold Coin',
      weight: 1.0,
      purity: '24K',
      stock: 100,
      readyStock: 10,
      categoryId: coinsCat.id,
      makingCharges: 250,
      imageUrl: 'https://pub-ee54ba2945a04c56b29b01ae5ec3c085.r2.dev/coin_1g.png'
    },
    {
      name: '5g 24K Gold Coin',
      weight: 5.0,
      purity: '24K',
      stock: 50,
      readyStock: 5,
      categoryId: coinsCat.id,
      makingCharges: 800,
      imageUrl: 'https://pub-ee54ba2945a04c56b29b01ae5ec3c085.r2.dev/coin_5g.png'
    }
  ];

  for (const p of products) {
    await prisma.product.create({
      data: {
        ...p,
        weight: new Prisma.Decimal(p.weight),
        makingCharges: new Prisma.Decimal(p.makingCharges),
      }
    });
  }
  console.log('✅ Products seeded');

  // 6. Initial Gold Price
  await prisma.goldPrice.create({
    data: {
      buyPrice: new Prisma.Decimal(7200),
      sellPrice: new Prisma.Decimal(7500),
    }
  });
  console.log('✅ Gold prices seeded');

  console.log('🏁 Seed Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

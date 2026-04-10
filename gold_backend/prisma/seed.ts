import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding categories...');
  
  const categories = [
    { name: 'Coins', slug: 'coins' },
    { name: 'Bars', slug: 'bars' },
    { name: 'Investment', slug: 'investment' },
    { name: 'Gifting', slug: 'gifting' },
    { name: 'Custom', slug: 'custom' },
    { name: 'Zodiac', slug: 'zodiac' },
    { name: 'Spiritual', slug: 'spiritual' },
    { name: 'Life Moments', slug: 'life-moments' },
    { name: 'Rewards', slug: 'rewards' },
    { name: 'Limited Edition', slug: 'limited-edition' }
  ];

  for (const cat of categories) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: { name: cat.name },
      create: {
        name: cat.name,
        slug: cat.slug,
        isActive: true,
      },
    });
  }

  console.log('Seeding products...');
  
  const coinsCat = await prisma.category.findUnique({ where: { slug: 'coins' } });
  const barsCat = await prisma.category.findUnique({ where: { slug: 'bars' } });

  if (coinsCat && barsCat) {
    const products = [
      {
        name: 'Royal Gold 1g Coin',
        description: '24K 999.9 Purity Gold Coin',
        weight: 1.0,
        purity: '24K',
        stock: 50,
        categoryId: coinsCat.id,
      },
      {
        name: 'Royal Gold 5g Coin',
        description: '24K 999.9 Purity Gold Coin',
        weight: 5.0,
        purity: '24K',
        stock: 20,
        categoryId: coinsCat.id,
      },
      {
        name: 'Royal Gold 10g Bar',
        description: 'Investment Grade Gold Bar',
        weight: 10.0,
        purity: '24K',
        stock: 10,
        categoryId: barsCat.id,
      },
    ];

    for (const prod of products) {
      await prisma.product.create({
        data: prod,
      });
    }
  }

  console.log('Seeding Gold Price...');
  await prisma.goldPrice.create({
    data: {
      buyPrice: 7500.0,
      sellPrice: 7600.0,
    }
  });

  console.log('Seeding Admin User...');
  await prisma.user.upsert({
    where: { phone: '9999999999' },
    update: {},
    create: {
      name: 'Main Admin',
      phone: '9999999999',
      email: 'admin@royalgold.app',
      password: 'admin-password-2026', // They use OTP, but password is required
      role: 'ADMIN',
      referralCode: 'ADMIN777',
      wallet: {
        create: {
          balance: 0,
        }
      }
    },
  });

  console.log('Seeding Global Settings...');
  const settings = [
    { key: 'delivery_days', value: '7', description: 'Standard delivery days after payment' },
    { key: 'referral_reward', value: '500', description: 'Fixed reward for successful referrals' },
    { key: 'min_withdrawal', value: '1000', description: 'Minimum balance required to request withdrawal' }
  ];

  for (const s of settings) {
    await prisma.setting.upsert({
      where: { key: s.key },
      update: {},
      create: s,
    });
  }

  console.log('Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

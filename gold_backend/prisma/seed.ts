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

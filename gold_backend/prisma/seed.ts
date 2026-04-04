import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // 1. Create Gold Price (Initial)
  const goldPrice = await prisma.goldPrice.create({
    data: {
      sellPrice: 7500.00, // INR per gram
      buyPrice: 7200.00,
    },
  });
  console.log('✅ Created Gold Price:', goldPrice.sellPrice);
  
  // 1.5. Create Admin User
  const admin = await prisma.user.upsert({
    where: { phone: '9999999999' },
    update: {
      role: 'ADMIN',
    },
    create: {
      name: 'Super Admin',
      email: 'admin@royalgold.app',
      phone: '9999999999',
      password: 'admin-password-2026',
      role: 'ADMIN',
      wallet: {
        create: {
          balance: 0,
          goldAdvance: 0,
        }
      }
    },
  });
  console.log('✅ Created Admin User:', admin.phone);

  // 2. Create Categories
  const categoriesData = [
    { name: 'Coins', slug: 'coins' },
    { name: 'Bars', slug: 'bars' },
    { name: 'Investment', slug: 'investment' },
    { name: 'Gifting', slug: 'gifting' },
    { name: 'Custom', slug: 'custom' },
    { name: 'Zodiac', slug: 'zodiac' },
    { name: 'Spiritual', slug: 'spiritual' },
    { name: 'Life Moments', slug: 'life-moments' },
    { name: 'Rewards', slug: 'rewards' },
    { name: 'Limited Edition', slug: 'limited-edition' },
  ];

  const categoriesMap: Record<string, string> = {};
  for (const cat of categoriesData) {
    const created = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {},
      create: {
        name: cat.name,
        slug: cat.slug,
      },
    });
    categoriesMap[cat.name] = created.id;
    console.log(`✅ Seeded Category: ${created.name}`);
  }

  // 3. Create Products
  const products = [
    {
      name: '1g 24K Gold Coin',
      description: '999.9 Purity fine gold coin from Royal Gold Traders.',
      weight: 1.0,
      purity: '24K',
      stock: 100,
      imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&q=80&w=800',
      categoryName: 'Coins',
    },
    {
      name: '5g 24K Gold Coin',
      description: 'Investment grade 5 gram gold coin with hallmark.',
      weight: 5.0,
      purity: '24K',
      stock: 50,
      imageUrl: 'https://images.unsplash.com/photo-1589118949245-7d4d45aa6212?auto=format&fit=crop&q=80&w=800',
      categoryName: 'Coins',
    },
    {
      name: '10g 24K Gold Coin',
      description: 'Premium 10 gram gold coin for long-term wealth.',
      weight: 10.0,
      purity: '24K',
      stock: 30,
      imageUrl: 'https://images.unsplash.com/photo-1618409399922-031955ec3f4a?auto=format&fit=crop&q=80&w=800',
      categoryName: 'Coins',
    },
  ];

  for (const product of products) {
    const { categoryName, ...productRecord } = product;
    const created = await prisma.product.upsert({
      where: { id: `seed-${product.weight}` },
      update: {
        categoryId: categoriesMap[categoryName],
      },
      create: {
        id: `seed-${product.weight}`,
        ...productRecord,
        weight: new Prisma.Decimal(product.weight),
        categoryId: categoriesMap[categoryName],
      },
    });
    console.log(`✅ Seeded Product: ${created.name}`);
  }

  console.log('🚀 Seeding complete!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

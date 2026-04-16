import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function checkPrice() {
  try {
    const price = await prisma.goldPrice.findFirst({
      orderBy: { timestamp: 'desc' },
    });
    console.log(JSON.stringify(price, null, 2));
  } catch (e) {
    console.error(e);
  } finally {
    await prisma.$disconnect();
  }
}

checkPrice();

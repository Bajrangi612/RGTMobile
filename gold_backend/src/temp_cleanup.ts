import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function cleanData() {
  try {
    const deleted = await prisma.$executeRawUnsafe(`DELETE FROM User WHERE phone IS NULL OR phone = ''`);
    console.log(`Deleted ${deleted} users with null or empty phone`);
  } catch (error) {
    console.error('Error cleaning data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

cleanData();

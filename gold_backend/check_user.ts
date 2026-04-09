import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function check() {
  const users = await prisma.user.findMany({
    where: {
      OR: [
        { phone: '9999999999' }
      ]
    }
  });
  console.log(JSON.stringify(users, null, 2));
}

check();

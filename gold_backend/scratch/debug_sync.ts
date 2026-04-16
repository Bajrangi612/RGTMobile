import ProductService from '../src/services/ProductService';
import { prisma } from '../src/lib/prisma';

async function debugSync() {
  console.log("🛠️ Starting Manual Debug Sync...");
  try {
    const result = await ProductService.performLiveMarketSync();
    console.log("✅ Sync Success:", JSON.stringify(result, null, 2));
  } catch (e: any) {
    console.error("❌ Sync Failed with error:");
    console.error(e.message);
    if (e.stack) console.error(e.stack);
  } finally {
    await prisma.$disconnect();
  }
}

debugSync();

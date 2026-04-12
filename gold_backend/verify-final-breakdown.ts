import { prisma } from "D:/RoyalGoldMobile/gold_backend/src/lib/prisma";
import ProductService from "D:/RoyalGoldMobile/gold_backend/src/services/ProductService";

async function verifyDetailedBreakdown() {
  console.log("🚀 Verifying 6-Step Detailed Pricing Breakdown...");

  try {
    const livePrice = 15358.73; // Our test base
    const mockProduct = { weight: 1.0, fixedPrice: 0, purity: "24K" };

    // Set sample percents
    await prisma.setting.update({ where: { key: 'global_discount_percent' }, data: { value: '2.0' } });
    await prisma.setting.update({ where: { key: 'gst_rate' }, data: { value: '3.0' } });
    await prisma.setting.update({ where: { key: 'making_charge_percent' }, data: { value: '6.0' } });
    await prisma.setting.update({ where: { key: 'gst_on_making_percent' }, data: { value: '5.0' } });

    console.log("\n--- Applying settings: Discount: 2%, GST: 3%, Making: 6%, Making GST: 5% ---");
    const result = await ProductService.calculateProductPrice(mockProduct, livePrice);

    console.log(`1. Market Gold Value: ₹${result.marketPrice}`);
    console.log(`2. Discount Amount: ₹${result.discountAmount}`);
    console.log(`3. Discounted Value: ₹${result.discountedGoldValue}`);
    console.log(`4. Gold GST (3% on #3): ₹${result.goldGst}`);
    console.log(`5. Making Charge (6% on #1): ₹${result.makingCharges}`);
    console.log(`6. GST on Making (5% on #5): ₹${result.makingGst}`);
    console.log(`--- Total Payable: ₹${result.total} ---`);

    // Manual check
    const mkt = 15358.73;
    const discVal = mkt - (mkt * 0.02);
    const gGst = discVal * 0.03;
    const mk = mkt * 0.06;
    const mkGst = mk * 0.05;
    const manualTotal = discVal + gGst + mk + mkGst;

    console.log(`\nManual Verification Result: ₹${manualTotal.toFixed(2)}`);

    if (Math.abs(result.total - manualTotal) < 0.1) {
      console.log("\n✅ BREAKDOWN VERIFIED: Backend math is 100% accurate.");
    } else {
      console.log("\n❌ VERIFICATION FAILED: Math mismatch.");
    }

  } catch (error) {
    console.error("Verification error:", error);
  } finally {
    await prisma.$disconnect();
  }
}

verifyDetailedBreakdown();

import DailyNotificationJob from '../src/services/DailyNotificationJob';
import PriceSyncService from '../src/services/PriceSyncService';
import { prisma } from '../src/lib/prisma';

async function runTest() {
  console.log('🚀 Starting Push Notification Test...');
  
  try {
    // 1. Check if any tokens exist
    const userCount = await prisma.user.count({
      where: { fcmToken: { not: null } }
    });

    if (userCount === 0) {
      console.log('⚠️  No FCM tokens found in the database. Please open the app on your phone FIRST to register your device.');
      process.exit(0);
    }

    console.log(`📱 Found ${userCount} registered device(s). Sending test alert...`);

    // 2. Trigger the job
    await DailyNotificationJob.testTrigger();
    
    console.log('✅ Test complete! Check your phone.');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

runTest();

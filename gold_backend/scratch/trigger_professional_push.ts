import DailyNotificationJob from '../src/services/DailyNotificationJob';

async function triggerTest() {
  console.log('🚀 Triggering Professional Notification Test...');
  try {
    await DailyNotificationJob.testTrigger();
    console.log('✅ Test trigger command sent successfully. Check backend logs for delivery status.');
  } catch (error) {
    console.error('❌ Test trigger failed:', error);
  }
}

triggerTest();

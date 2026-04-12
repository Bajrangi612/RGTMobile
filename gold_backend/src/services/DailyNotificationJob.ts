import * as cron from 'node-cron';
import { prisma } from "../lib/prisma";
import PriceSyncService from "./PriceSyncService";
import NotificationService from "./NotificationService";

class DailyNotificationJob {
  private job: cron.ScheduledTask | null = null;

  /**
   * Start the daily morning notification job
   * Run at 9:00 AM IST (which is 3:30 AM UTC)
   */
  start() {
    console.log('📅 [DailyJob] Initializing Gold Rate Notifications (Scheduled for 09:00 AM and 06:00 PM IST)...');

    // Cron schedule for 9:00 AM and 6:00 PM IST
    // '0 9,18 * * *'
    const schedule = '0 9,18 * * *'; 

    this.job = cron.schedule(schedule, async () => {
      console.log('🔔 [DailyJob] Triggering Gold Rate Alert...');
      await this.sendDailyRateNotification();
    });
  }

  async sendDailyRateNotification() {
    try {
      // 1. Ensure we have the latest price
      const price = await PriceSyncService.performSync();
      
      const sellPrice = parseFloat(price.sellPrice.toString());
      const formattedPrice = sellPrice.toLocaleString('en-IN');

      // 2. Fetch all users with valid FCM tokens
      const users = await prisma.user.findMany({
        where: {
          fcmToken: { not: null },
          isActive: true
        },
        select: { id: true, name: true, fcmToken: true }
      });

      if (users.length === 0) {
        console.log('ℹ️ [DailyJob] No users with valid tokens found. Skipping.');
        return;
      }

      const title = "✨ Today's Gold Rate is here!";
      const body = `Live 24K Gold Rate: ₹${formattedPrice}/gm. Check our special festive offers today!`;

      // 3. Dispatch notifications
      // For large user bases, we'd use multicast, but here we loop for simplicity and per-user personalization if needed
      let successCount = 0;
      for (const user of users) {
        try {
          await NotificationService.sendPushNotification(user.id, title, body, 'GOLD_RATE_UPDATE');
          successCount++;
        } catch (err) {
          // Individual failure ok
        }
      }

      console.log(`✅ [DailyJob] Successfully dispatched rate alert to ${successCount}/${users.length} users.`);

    } catch (error) {
      console.error('❌ [DailyJob] Critical failure in daily notification:', error);
    }
  }

  /**
   * Manual trigger for testing
   */
  async testTrigger() {
    console.log('🧪 [DailyJob] Manual test trigger initiated...');
    await this.sendDailyRateNotification();
  }
}

export default new DailyNotificationJob();

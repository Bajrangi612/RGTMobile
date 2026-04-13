import * as cron from 'node-cron';
import { prisma } from "../lib/prisma";
import PriceSyncService from "./PriceSyncService";
import NotificationService from "./NotificationService";
import { Decimal } from "@prisma/client/runtime/library";

const BRANDED_BANNER_URL = 'https://pub-ee54ba2945a04c56b29b01ae5ec3c085.r2.dev/notifications/royal_gold_banner_1776059299396.png';

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
        where: { fcmToken: { not: null } },
        select: { id: true, name: true, fcmToken: true }
      });

      if (users.length === 0) return;

      // 3. Get Member Price (Apply Global Discount)
      const discountSetting = await prisma.setting.findUnique({ where: { key: 'global_discount_percent' } });
      const discountPercent = discountSetting ? parseFloat(discountSetting.value) : 0.0;
      const memberPrice = sellPrice * (1 - discountPercent / 100);

      const title = "✨ Today's Live Gold Rate is here!";
      const body = `📈 Market: ₹${sellPrice.toLocaleString('en-IN')}/gm | Your Price: ₹${memberPrice.toLocaleString('en-IN')}/gm. Secure your 24K gold at today's best rates. Tap to buy now! 🚀`;

      // 4. Dispatch professional notifications
      let successCount = 0;
      for (const user of users) {
        try {
          await NotificationService.sendPushNotification(
            user.id, 
            title, 
            body, 
            'GOLD_RATE_UPDATE', 
            { sellPrice: sellPrice.toString(), memberPrice: memberPrice.toString() },
            BRANDED_BANNER_URL
          );
          successCount++;
        } catch (err) { }
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

  /**
   * Send a system startup notification with market vs member price comparison
   */
  async sendSystemStartupNotification() {
    try {
      console.log('🚀 [DailyJob] Sending system startup notification...');

      // 1. Get Market Price
      const price = await PriceSyncService.performSync();
      const marketPrice = parseFloat(price.sellPrice.toString());

      // 2. Get Discount %
      const discountSetting = await prisma.setting.findUnique({ where: { key: 'global_discount_percent' } });
      const discountPercent = discountSetting ? parseFloat(discountSetting.value) : 0.0;

      // 3. Calculate Member Price
      const discountAmount = marketPrice * (discountPercent / 100);
      const memberPrice = marketPrice - discountAmount;

      const title = "🚀 System Online: Live Gold Rates";
      const body = `📈 Market: ₹${marketPrice.toLocaleString('en-IN')}/gm | Your Price: ₹${memberPrice.toLocaleString('en-IN')}/gm. Secure your 24K gold at today's best rates. Tap to buy now! 🚀`;

      // 4. Send to all registered users
      const users = await prisma.user.findMany({
        where: { fcmToken: { not: null } },
        select: { id: true }
      });

      for (const user of users) {
        await NotificationService.sendPushNotification(
          user.id, 
          title, 
          body, 
          'SYSTEM_STARTUP',
          { marketPrice: marketPrice.toString(), memberPrice: memberPrice.toString() },
          BRANDED_BANNER_URL
        );
      }

      console.log(`✅ [DailyJob] Startup notification sent to ${users.length} devices.`);
    } catch (error) {
      console.error('❌ [DailyJob] Failed to send startup notification:', error);
    }
  }
}

export default new DailyNotificationJob();

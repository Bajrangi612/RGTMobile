import { prisma } from "../lib/prisma";

class NotificationService {
  constructor() {}

  async sendPushNotification(userId: string, title: string, body: string, type: string = 'GENERAL', data?: any) {
    try {
      // 1. Persist to Database for In-App Notification Center
      await prisma.notification.create({
        data: {
          userId,
          title,
          body,
          type,
        }
      });

      // 2. Fetch User's FCM token
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true }
      });

      if (user?.fcmToken) {
        console.log(`[FCM MOCK] Sending to ${user.fcmToken}: ${title} - ${body}`);
      } else {
        console.log(`[FCM] No token found for user ${userId}, skipped push notification.`);
      }
      
    } catch (error) {
      console.error("Error sending push notification:", error);
    }
  }

  async sendToTopic(topic: string, title: string, body: string, data?: any) {
    console.log(`[FCM MOCK] Sending to topic ${topic}: ${title} - ${body}`);
  }
}

export default new NotificationService();

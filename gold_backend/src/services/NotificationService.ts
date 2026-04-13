import { prisma } from "../lib/prisma";
import admin from "../lib/firebase";

class NotificationService {
  constructor() {}

  async sendPushNotification(userId: string, title: string, body: string, type: string = 'GENERAL', data?: any, imageUrl?: string) {
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

      if (user?.fcmToken && admin.apps.length > 0) {
        try {
          await admin.messaging().send({
            token: user.fcmToken,
            notification: { 
              title, 
              body,
              image: imageUrl, // Standard image support
            },
            data: { 
              ...data, 
              type,
              imageUrl: imageUrl || '', // Pass to app for foreground handling
            },
            android: {
              priority: 'high',
              notification: {
                imageUrl: imageUrl,
                channelId: 'high_importance_channel', // Matches Flutter app config
                priority: 'high',
                sticky: false,
                visibility: 'public',
              }
            },
            apns: {
              payload: {
                aps: {
                  mutableContent: true, // Required for iOS images
                  sound: 'default',
                }
              },
              fcmOptions: {
                imageUrl: imageUrl
              }
            }
          });
          console.log(`✅ [FCM] Sent professional notification to user ${userId}`);
        } catch (fcmError) {
          console.error(`❌ [FCM] Failed to send to token:`, fcmError);
          // Optional: clear invalid token if it's expired
        }
      } else {
        console.log(`ℹ️ [FCM] No dispatch: ${!user?.fcmToken ? 'No token' : 'Admin SDK not initialized'}`);
      }
      
    } catch (error) {
      console.error("Error sending push notification:", error);
    }
  }

  async sendToTopic(topic: string, title: string, body: string, data?: any) {
    if (admin.apps.length === 0) return;
    try {
      await admin.messaging().send({
        topic,
        notification: { title, body },
        data: data ? { ...data } : undefined,
      });
      console.log(`✅ [FCM] Sent notification to topic: ${topic}`);
    } catch (error) {
      console.error("Error sending to topic:", error);
    }
  }
}

export default new NotificationService();

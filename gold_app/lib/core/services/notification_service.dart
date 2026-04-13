import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../network/api_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Initialize Firebase (This is called in main.dart usually)
    // To be safer, we handle it here or ensure it's called there.
    
    // 2. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
      
      // 3. Get Device Token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Send to backend
        _updateTokenOnBackend(token);
      }

      // 4. Set up Listeners
      _initLocalNotifications();
      _setupMessageHandlers();
    }
  }

  static void _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click while app is open
      },
    );
  }

  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      // Extract imageUrl from payload
      String? imageUrl = message.data['imageUrl'] ?? message.notification?.android?.imageUrl;

      if (notification != null) {
        String? largeIconPath;
        String? bigPicturePath;

        // Download image if available for Big Picture style
        if (imageUrl != null && imageUrl.isNotEmpty) {
          bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture.png');
        }

        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: bigPicturePath != null 
                ? BigPictureStyleInformation(
                    FilePathAndroidBitmap(bigPicturePath),
                    hideExpandedLargeIcon: true,
                    contentTitle: notification.title,
                    summaryText: notification.body,
                  )
                : null,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Handle background/terminated state messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('User clicked notification and opened app');
    });
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    await Dio().download(url, filePath);
    return filePath;
  }

  static Future<void> _updateTokenOnBackend(String token) async {
    try {
      await ApiService().updateFcmToken(token);
    } catch (e) {
      debugPrint('Failed to update FCM token on backend: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
}

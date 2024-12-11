import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'fcm_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const androidNotificationChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationTap(details);
        },
      );

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessage(message);
        }
      });

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessage(message);
      });
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      rethrow;
    }
  }

  static void _handleNotificationTap(NotificationResponse details) {
    if (details.payload != null) {
      // Navigate to specific screen based on payload
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      await _notifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidNotificationChannel.id,
            androidNotificationChannel.name,
            channelDescription: androidNotificationChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'],
      );
    }
  }

  static Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['route'] != null) {
      // Navigate to specific screen based on route
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    log("Handling a background message: ${message.messageId}");
    await _handleForegroundMessage(message);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'canteen_app_channel',
      'Canteen App Notifications',
      channelDescription: 'Notifications from Canteen App',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> subscribeToUserNotifications(String userId) async {
    await _messaging.subscribeToTopic('user_$userId');
  }

  static Future<void> subscribeToCafeNotifications(String cafeId) async {
    await _messaging.subscribeToTopic('cafe_$cafeId');
  }

  static Future<void> unsubscribeFromUserNotifications(String userId) async {
    await _messaging.unsubscribeFromTopic('user_$userId');
  }

  static Future<void> unsubscribeFromCafeNotifications(String cafeId) async {
    await _messaging.unsubscribeFromTopic('cafe_$cafeId');
  }

// _______________________________________
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  static AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  static initNotification() async {
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  static showLocalNotification(String title, String body, String payload) {
    const androidNotificationDetail = AndroidNotificationDetails(
      '0',
      'general',
      priority: Priority.high,
      autoCancel: false,
      fullScreenIntent: true,
      enableVibration: true,
      importance: Importance.high,
      playSound: true,
    );
    const iosNotificatonDetail = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      iOS: iosNotificatonDetail,
      android: androidNotificationDetail,
    );
    flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails,
        payload: payload);
  }

  static Future<void> saveTokenToDatabase(String userId, bool isCafe) async {
    try {
      String? token = await _messaging.getToken();

      if (token == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    bool isCafe = false,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final userData = doc.data();

      // Check if the user type matches (cafe or customer)
      if (userData?['type'] != (isCafe ? 'cafe' : 'customer')) {
        print('User type mismatch');
        return;
      }

      final fcmToken = userData?['fcmToken'] as String?;
      log('${userData?['type']} FCM token: $fcmToken');

      if (fcmToken != null) {
        await FCMService().sendNotification(
          recipientFCMToken: fcmToken,
          title: title,
          body: body,
        );
      }
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }
}

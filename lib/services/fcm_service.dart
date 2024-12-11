import 'dart:convert';
import 'dart:developer';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
    'https://www.googleapis.com/auth/firebase.database',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  Future<String> _getAccessToken() async {
    try {
      final serviceAccountJson = dotenv.get('FIREBASE_SERVICE_ACCOUNT');
      final serviceAccountJsonDecoded = {};
      log('Loading service account...');

      if (serviceAccountJson.isEmpty) {
        throw Exception('FIREBASE_SERVICE_ACCOUNT not found in .env file');
      }
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJsonDecoded,
      );

      final client = await clientViaServiceAccount(credentials, scopes);

      return client.credentials.accessToken.data;
    } catch (e) {
      log('Error getting access token: $e');
      rethrow;
    }
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notify');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'cafe_orders',
      'Cafe Orders',
      channelDescription: 'Notifications for cafe orders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      enableVibration: true,
      icon: '@drawable/ic_stat_notify',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<bool> sendNotification({
    required String recipientFCMToken,
    required String title,
    required String body,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      log('access token: $accessToken');
      final projectId = dotenv.get('FIREBASE_PROJECT_ID');

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': recipientFCMToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'category': 'NEW_NOTIFICATION',
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        log('Notification sent successfully');
        return true;
      } else {
        log('FCM Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error sending notification: $e');
      return false;
    }
  }
}

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
      final serviceAccountJsonDecoded = {
        "type": "service_account",
        "project_id": "unicanteenvirtualqueue",
        "private_key_id": "43626c713098dfcf418f9c125f50b96b4c590fe6",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCiXDHYQh4gVweT\nlBezwLVXbBNN3clbO7cBZNvnFC0D9E9wc5zSWgn1HD3fkoLQFQYXy1zeA9F2Dowm\ngNqDi7BpI6+it815gSMsfV8dm8u5RInajGjiWXlN0X9o+nbaJQOtaLXfmUMU4wb/\nIKEV1K/mZADOe+o1Cpx8SwzJNQo8rDb2b15lcIAmpzqCv5pgv5VwDJT0mVi4cOAn\niRaJbuLVsIJDzksZFZwNwIleR8TySlbdJ41ULrhsfPdAECT5EIm5RBTB1madwrd8\nJXwo6PjFTW8Dy0aRGPcW3tckAVxjt/rF8tHZwIpu6bydd1+ECq0tdigSfW1c38Hi\ngrKiHuunAgMBAAECggEABrYS5WKORj3ytTn45NhBZrSz85MIYLoOLYOSx3GBDtnJ\ncteEkvlf0f7x28z9lUZZMyCX3SGBRgUB7BGFdsyOZToxZ2N7ndslrhAcn2eyOx1H\nKX6GU1zpc7sGLju0L/45sbBTXEPEjxd3UZJytilNgBOAKQjcPIcMwuKDS8nie3F+\nDkg2XhXrsq5Uvx7qdNwMX9yIPwsqYiczf7NsDTgrlG3S5UtOAL16PApjW0ITaRBD\nv1D553vn/aofDeyz3D2PwssXF7cdlzmQJGOI+7cfdEWAhhHmI8D4wdixfzwbLQzz\n+M5SWv0PF3ivlVc5BQiG8dLTS9TpA9gjy8niFyHkqQKBgQDX4ASx12JwYs9SoUys\n2Gf9Nv55dObbxYS1LRjZ/WHDeksv1UA8xniYSYWX1OtAZknkUO7RW4VAIrhiStc0\nM8kfri8YltR5RkJNeCN24KLDpE3x6VLX4Zucih5GErmvTDfz7Y7/DayA6eWilq1W\no3bJnk6mvhrcp+Mtib9VcjvJ9QKBgQDAicaPnBuwpC7mU3KW/fJc+uIPcWOKVnhY\nEF6u1MuO/8mOPTUCUSaDq5n5CRWUaODnAthS2BPU8EQWs6max/rGVgjOKjtapVrc\n7pZBdH15Ugwrx43dMEhKgITnotjiL5XapGMljLlnfy2U9+BlpuGR4NLqooRQ8Vt9\nxJ4kfFbRqwKBgQCu4PCMrWI2jyVK2BaIU0tyqvFdrSEz2n/WUbE3Lvfa5qAwIL5I\nPbQGElFiHX9yjSrBBfthqJV6zmW2YtCRnn4I5w+KCO4ZTJx7q553OCVC/kCSf6S3\n9DEekBlUROkdpE4TklfsMMSVLmXz38KOVB/v1wn6NDkIlg0In/VbIA5lXQKBgFqj\ngXoxv0dUw09ikVtLiUEESk+CzZ1eP6EVc71SJ9HV0IjJf57rnPn3WrDF+ga3qMiX\nqka1ugBQa31Ubs+SvReJgPOtJevyU+gV2V5O/JKUcW5arwolpKKOBgMVwowYYq9f\nG92dddqnIEo0tsqj2STXdfNHNor0VGHMobYDYsupAoGADJi1hrveFTnMOWgSfE7B\n25woLhi+Ef78OYwTSss5qb66EXnPMhpUuVel/sN105Gium7a9yKY9jeOn/je5LMl\nZ7Q7K2PvtMeeaEddBNsSdV/cj33D5YwMBh0/LmoRCgAv4du9ZAR2bE5uqZ7XNauc\nQVn1RQWTCZ3ceVAl94IoCWc=\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-kqci7@unicanteenvirtualqueue.iam.gserviceaccount.com",
        "client_id": "104624590474113483864",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-kqci7%40unicanteenvirtualqueue.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      };
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

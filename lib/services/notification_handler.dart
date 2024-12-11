import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../models/user_type.dart';
import '../providers/auth_provider.dart';
import '../screens/cafe/order_management_screen.dart';
import 'fcm_service.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({super.key, required this.child});

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _fcmService.showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleNotification(RemoteMessage message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;

    // Skip if this notification was sent by the current user
    if (message.data['senderId'] == currentUserId) {
      return;
    }

    // Only show notifications meant for the current user type
    if (message.data['recipientType'] == 'cafe' &&
        authProvider.userType == UserType.cafe) {
      // Show notifications for café users
      if (message.data['type'] == 'new_order') {
        _showNewOrderDialog(message);
      }
    } else if (message.data['recipientType'] == 'customer' &&
        authProvider.userType == UserType.customer) {
      // Show notifications for customer users
      if (message.data['type'] == 'order_update') {
        _showOrderUpdateSnackBar(message);
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Handle navigation based on user type and notification type
    if (authProvider.userType == UserType.cafe &&
        message.data['recipientType'] == 'cafe') {
      if (message.data['type'] == 'new_order') {
        // Navigate to order management screen for café
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OrderManagementScreen(),
          ),
        );
      }
    } else if (authProvider.userType == UserType.customer &&
        message.data['recipientType'] == 'customer') {
      if (message.data['type'] == 'order_update') {
        // Navigate to order details/history for customer
        // Add your customer order screen navigation here
      }
    }
  }

  void _showNewOrderDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message.notification?.title ?? 'New Order'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Navigate to order management screen
            },
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  void _showOrderUpdateSnackBar(RemoteMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.body ?? ''),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to order details
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // await Firebase.initializeApp();

  final fcmService = FCMService();
  await fcmService.initialize();

  await fcmService.showNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    payload: message.data.toString(),
  );
}

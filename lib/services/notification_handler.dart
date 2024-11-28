import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({super.key, required this.child});

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  void _handleNotification(RemoteMessage message) {
    if (message.data['type'] == 'new_order') {
      _showNewOrderDialog(message);
    } else if (message.data['type'] == 'order_update') {
      _showOrderUpdateSnackBar(message);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation when notification is tapped
    if (message.data['type'] == 'new_order') {
      // Navigate to order management screen
    } else if (message.data['type'] == 'order_update') {
      // Navigate to order details screen
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
              // Navigate to order management screen
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

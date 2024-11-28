import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'customer/customer_home_screen.dart';
import 'cafe/cafe_home_screen.dart';
import 'auth/login_screen.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndUpdateToken();
  }

  Future<void> _checkAuthAndUpdateToken() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initializeUserType(); // Initialize user type first

    // Update FCM token for existing users
    if (authProvider.isAuthenticated) {
      final userId = authProvider.userId;
      final fcmToken = await NotificationService.getToken();

      if (userId != null && fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        // Subscribe to appropriate topics based on user type
        if (authProvider.userType == UserType.customer) {
          await NotificationService.subscribeToUserNotifications(userId);
        } else {
          await NotificationService.subscribeToCafeNotifications(userId);
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.userType == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => authProvider.userType == UserType.customer
              ? const CustomerHomeScreen()
              : const CafeHomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Canteen Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

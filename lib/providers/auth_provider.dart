import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/cafe/cafe_home_screen.dart';
import '../services/notification_service.dart';

enum UserType { customer, cafe }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserType? _userType;
  bool _isLoading = false;

  bool get isAuthenticated => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  UserType? get userType => _userType;
  bool get isLoading => _isLoading;

  Future<void> _updateFCMToken(String userId) async {
    try {
      final fcmToken = await NotificationService.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  Future<void> initializeUserType() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserType(user.uid);
      await _updateFCMToken(user.uid);
    }
  }

  Future<void> _loadUserType(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      _userType =
          userDoc.data()?['type'] == 'cafe' ? UserType.cafe : UserType.customer;
      notifyListeners();
    } catch (e) {
      log('Error loading user type: $e');
    }
  }

  Future<void> signIn(
      String email, String password, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserType(userCredential.user!.uid);
      await _updateFCMToken(userCredential.user!.uid);

      if (!context.mounted) return;

      if (_userType == UserType.customer) {
        await NotificationService.subscribeToUserNotifications(
            userCredential.user!.uid);
      } else {
        await NotificationService.subscribeToCafeNotifications(
            userCredential.user!.uid);
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _userType == UserType.customer
              ? const CustomerHomeScreen()
              : const CafeHomeScreen(),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Login failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name, UserType type,
      BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fcmToken = await NotificationService.getToken();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'type': type == UserType.cafe ? 'cafe' : 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      _userType = type;

      if (_userType == UserType.customer) {
        await NotificationService.subscribeToUserNotifications(
            userCredential.user!.uid);
      } else {
        await NotificationService.subscribeToCafeNotifications(
            userCredential.user!.uid);
      }

      if (!context.mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _userType == UserType.customer
              ? const CustomerHomeScreen()
              : const CafeHomeScreen(),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Sign up failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        if (_userType == UserType.customer) {
          await NotificationService.unsubscribeFromUserNotifications(userId);
        } else {
          await NotificationService.unsubscribeFromCafeNotifications(userId);
        }

        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }

      await _auth.signOut();
      _userType = null;

      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      _showErrorDialog(context, 'Sign out failed: ${e.toString()}');
    }
    notifyListeners();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

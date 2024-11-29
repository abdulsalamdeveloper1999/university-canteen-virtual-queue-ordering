import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/cafe/cafe_home_screen.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _userType;
  bool _isLoading = false;

  User? get user => _user;
  String? get userType => _userType;
  String? get userId => user?.uid;
  bool get isCafe => _userType == 'cafe';
  bool get isAuthenticated => user != null;
  bool get isLoading => _isLoading;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String type, // 'cafe' or 'customer'
    String? cafeLocation,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'type': type,
          'cafeLocation': type == 'cafe' ? cafeLocation : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _user = userCredential.user;
        _userType = type;

        // Save FCM token
        await NotificationService.saveTokenToDatabase(
          userCredential.user!.uid,
          type == 'cafe',
        );

        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _user = userCredential.user;

        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists) {
          throw Exception('User document not found');
        }

        _userType = doc.data()?['type'] as String?;

        if (_userType == null) {
          throw Exception('User type not found');
        }

        await NotificationService.saveTokenToDatabase(
          userCredential.user!.uid,
          _userType == 'cafe',
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void navigateAfterAuth(BuildContext context) {
    if (_userType == 'cafe') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CafeHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userType = null;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    _user = _auth.currentUser;
    if (_user != null) {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userType = doc.data()?['type'] as String?;
        notifyListeners();
      } else {
        // If user document doesn't exist, sign out
        await signOut();
      }
    }
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

  Future<void> initializeUserType() async {
    if (_user != null) {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      _userType = doc.data()?['type'] as String?;
      notifyListeners();
    }
  }
}

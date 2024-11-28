import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class MenuProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;

  List<MenuItem> searchItems(String query) {
    query = query.toLowerCase();
    return _menuItems.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> fetchMenuItems(String cafeId) async {
    if (_isInitialized) return;

    try {
      _isLoading = true;

      final snapshot = await _firestore
          .collection('items')
          .where('cafeId', isEqualTo: cafeId)
          .get();

      _menuItems = snapshot.docs
          .map((doc) => MenuItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      // log('Error fetching menu items: $e');
      rethrow;
    }
  }

  Future<void> fetchAllMenuItems() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;

      final snapshot = await _firestore
          .collection('items')
          .where('isAvailable', isEqualTo: true)
          .get();

      _menuItems = snapshot.docs
          .map((doc) => MenuItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      // log('Error fetching all menu items: $e');
      rethrow;
    }
  }

  Stream<List<MenuItem>> streamMenuItems(String cafeId) {
    return _firestore
        .collection('items')
        .where('cafeId', isEqualTo: cafeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItem.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> updateQueueCount(String itemId, int newCount) async {
    try {
      await _firestore
          .collection('items')
          .doc(itemId)
          .update({'queueCount': newCount});
    } catch (e) {
      log('Error updating queue count: $e');
      rethrow;
    }
  }

  Future<void> addMenuItem(MenuItem item) async {
    try {
      await _firestore.collection('items').add(item.toJson());
    } catch (e) {
      log('Error adding menu item: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    try {
      await _firestore.collection('items').doc(item.id).update(item.toJson());
    } catch (e) {
      log('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      log('Error deleting menu item: $e');
      rethrow;
    }
  }

  Future<void> incrementQueueCount(
      String itemId, String orderId, int quantity) async {
    try {
      final docRef = _firestore.collection('items').doc(itemId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Item does not exist!');
        }

        final currentItem =
            MenuItem.fromJson({...snapshot.data()!, 'id': itemId});
        final newQueueCount = currentItem.queueCount + 1;
        final newOrderQuantities =
            Map<String, int>.from(currentItem.orderQuantities)
              ..addAll({orderId: quantity});

        transaction.update(docRef, {
          'queueCount': newQueueCount,
          'orderQuantities': newOrderQuantities,
        });
      });

      notifyListeners();
    } catch (e) {
      log('Error incrementing queue count: $e');
      rethrow;
    }
  }

  Future<void> decrementQueueCount(String itemId, String orderId) async {
    try {
      final docRef = _firestore.collection('items').doc(itemId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Item does not exist!');
        }

        final currentItem =
            MenuItem.fromJson({...snapshot.data()!, 'id': itemId});
        final newQueueCount = currentItem.queueCount - 1;
        final newOrderQuantities =
            Map<String, int>.from(currentItem.orderQuantities)..remove(orderId);

        transaction.update(docRef, {
          'queueCount': newQueueCount >= 0 ? newQueueCount : 0,
          'orderQuantities': newOrderQuantities,
        });
      });

      notifyListeners();
    } catch (e) {
      log('Error decrementing queue count: $e');
      rethrow;
    }
  }

  Stream<MenuItem> streamMenuItem(String itemId) {
    return _firestore
        .collection('items')
        .doc(itemId)
        .snapshots()
        .map((doc) => MenuItem.fromJson({...doc.data()!, 'id': doc.id}));
  }

  void reset() {
    _isInitialized = false;
    _menuItems = [];
    _isLoading = false;
    notifyListeners();
  }
}

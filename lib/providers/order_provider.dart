import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_order;
import 'cart_provider.dart';
import '../services/notification_service.dart';
import '../providers/menu_provider.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<app_order.Order> _orders = [];

  List<app_order.Order> get orders => [..._orders];

  Future<void> placeOrder(
      CartProvider cart, String customerId, String cafeId) async {
    try {
      final orderItems = cart.items.values
          .map((cartItem) => app_order.OrderItem(
                menuItemId: cartItem.menuItem.id,
                name: cartItem.menuItem.name,
                quantity: cartItem.quantity,
                price: cartItem.menuItem.price,
              ))
          .toList();

      final order = app_order.Order(
        id: DateTime.now().toString(),
        customerId: customerId,
        cafeId: cafeId,
        items: orderItems,
        status: app_order.OrderStatus.pending,
        createdAt: DateTime.now(),
        totalAmount: cart.totalAmount,
      );

      final docRef = await _firestore.collection('orders').add(order.toJson());
      final orderId = docRef.id;
      await docRef.update({'id': orderId});

      final menuProvider = MenuProvider();
      for (var item in orderItems) {
        await menuProvider.incrementQueueCount(
          item.menuItemId,
          orderId,
          item.quantity,
        );
      }

      await NotificationService.sendNotificationToUser(
        userId: cafeId,
        title: 'New Order',
        body: 'Order #${orderId.substring(0, 8)} has been placed',
        isCafe: true,
      );

      await NotificationService.showNotification(
        title: 'Order Placed',
        body: 'Your order #${orderId.substring(0, 8)} has been placed',
      );

      cart.clear();
      notifyListeners();
    } catch (e) {
      log('Error placing order: $e');
      rethrow;
    }
  }

  Stream<List<app_order.Order>> streamCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                app_order.Order.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<app_order.Order>> streamCafeOrders(String cafeId) {
    return _firestore
        .collection('orders')
        .where('cafeId', isEqualTo: cafeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                app_order.Order.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> updateOrderStatus(
    String orderId,
    app_order.OrderStatus status, {
    String? rejectionReason,
  }) async {
    try {
      log('Updating order status: $orderId to ${status.toString()}');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final order =
          app_order.Order.fromJson({...orderDoc.data()!, 'id': orderId});
      final customerId = order.customerId;

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last.toLowerCase(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });

      // Handle queue count updates for completed or rejected orders
      if (status == app_order.OrderStatus.completed ||
          status == app_order.OrderStatus.rejected) {
        final menuProvider = MenuProvider();
        for (var item in order.items) {
          await menuProvider.decrementQueueCount(item.menuItemId, orderId);
          log('Decremented queue count for item: ${item.menuItemId} due to ${status.toString()}');
        }
      }

      // Send notification to customer
      String title = '';
      String body = '';

      switch (status) {
        case app_order.OrderStatus.approved:
          title = 'Order Approved';
          body = 'Your order #${orderId.substring(0, 8)} has been approved';
          break;
        case app_order.OrderStatus.rejected:
          title = 'Order Rejected';
          body = rejectionReason ?? 'Your order has been rejected';
          break;
        case app_order.OrderStatus.preparing:
          title = 'Order Being Prepared';
          body = 'Your order #${orderId.substring(0, 8)} is being prepared';
          break;
        case app_order.OrderStatus.ready:
          title = 'Order Ready';
          body = 'Your order #${orderId.substring(0, 8)} is ready for pickup';
          break;
        case app_order.OrderStatus.completed:
          title = 'Order Completed';
          body = 'Your order #${orderId.substring(0, 8)} has been completed';
          break;
        default:
          log('Unhandled order status: $status');
          return;
      }

      log('Notification title: $title, body: $body');

      await NotificationService.sendNotificationToUser(
        userId: customerId,
        title: title,
        body: body,
        isCafe: false,
      );

      notifyListeners();
    } catch (e) {
      log('Error updating order status: $e');
      rethrow;
    }
  }

  Stream<List<app_order.Order>> streamPendingOrders(String cafeId) {
    log('Streaming pending orders for cafe: $cafeId');

    return _firestore
        .collection('orders')
        .where('cafeId', isEqualTo: cafeId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return app_order.Order.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              log('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .where((order) => order != null)
          .cast<app_order.Order>()
          .toList();
    });
  }

  Stream<List<app_order.Order>> streamActiveOrders(String cafeId) {
    return _firestore
        .collection('orders')
        .where('cafeId', isEqualTo: cafeId)
        .where('status', whereIn: ['approved', 'preparing', 'ready'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                app_order.Order.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<app_order.Order>> streamCompletedOrders(String cafeId) {
    return _firestore
        .collection('orders')
        .where('cafeId', isEqualTo: cafeId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                app_order.Order.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<app_order.Order>> streamRejectedOrders(String cafeId) {
    return _firestore
        .collection('orders')
        .where('cafeId', isEqualTo: cafeId)
        .where('status', isEqualTo: 'rejected')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                app_order.Order.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}

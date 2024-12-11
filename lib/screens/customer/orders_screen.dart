import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('My Orders'),
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Rejected'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersList(
              userId: authProvider.user!.uid,
              orderType: OrderListType.active,
            ),
            _OrdersList(
              userId: authProvider.user!.uid,
              orderType: OrderListType.completed,
            ),
            _OrdersList(
              userId: authProvider.user!.uid,
              orderType: OrderListType.rejected,
            ),
            _OrdersList(
              userId: authProvider.user!.uid,
              orderType: OrderListType.cancelled,
            ),
          ],
        ),
      ),
    );
  }
}

enum OrderListType { active, completed, rejected, cancelled }

class _OrdersList extends StatelessWidget {
  final String userId;
  final OrderListType orderType;

  const _OrdersList({
    required this.userId,
    required this.orderType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context).streamCustomerOrders(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        final orders = allOrders.where((order) {
          switch (orderType) {
            case OrderListType.active:
              return (order.status == OrderStatus.pending ||
                      order.status == OrderStatus.approved ||
                      order.status == OrderStatus.preparing ||
                      order.status == OrderStatus.ready) &&
                  order.status != OrderStatus.cancelled;
            case OrderListType.completed:
              return order.status == OrderStatus.completed;
            case OrderListType.rejected:
              return order.status == OrderStatus.rejected;
            case OrderListType.cancelled:
              return order.status == OrderStatus.cancelled;
          }
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Text(_getEmptyMessage(orderType)),
          );
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (ctx, i) => OrderCard(order: orders[i]),
        );
      },
    );
  }

  String _getEmptyMessage(OrderListType type) {
    switch (type) {
      case OrderListType.active:
        return 'No active orders';
      case OrderListType.completed:
        return 'No completed orders';
      case OrderListType.rejected:
        return 'No rejected orders';
      case OrderListType.cancelled:
        return 'No cancelled orders';
    }
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id.substring(0, 8)}'),
            Text(
              'Status: ${order.status.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                color: _getStatusColor(order.status),
              ),
            ),
            Text(
              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
            ),
            ...order.items.map(
              (item) => ListTile(
                title: Text(item.name),
                trailing: Text('${item.quantity}x \$${item.price}'),
              ),
            ),
            if (order.status == OrderStatus.rejected &&
                order.rejectionReason != null)
              ListTile(
                title: const Text('Rejection Reason:'),
                subtitle: Text(order.rejectionReason!),
                tileColor: Colors.red.withOpacity(0.1),
              ),
            if (order.status == OrderStatus.pending ||
                order.status == OrderStatus.approved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: () => _showCancelConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Order'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    String? selectedReason;
    final List<String> cancelReasons = [
      'Changed my mind',
      'Long waiting time',
      'Ordered by mistake',
      'Class/Meeting started',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please select a reason for cancellation:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Select reason'),
              items: cancelReasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                selectedReason = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedReason == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a reason for cancellation'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await context.read<OrderProvider>().cancelOrder(
                      order.id,
                      reason: selectedReason!,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel order'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.approved:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.grey;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.cancelled:
        return Colors.red.shade900;
    }
  }
}

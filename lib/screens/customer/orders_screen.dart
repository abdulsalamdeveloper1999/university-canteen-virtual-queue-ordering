import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../utils/search_delegates.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return DefaultTabController(
      length: 3,
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
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Rejected'),
            ],
          ),
          actions: [
            StreamBuilder<List<Order>>(
              stream: Provider.of<OrderProvider>(context)
                  .streamCustomerOrders(authProvider.userId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                return IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    try {
                      final Order? result = await showSearch<Order?>(
                        context: context,
                        delegate: OrderSearchDelegate(snapshot.data!),
                      );
                      if (result != null) {
                        // Handle selected order
                      }
                    } catch (e) {
                      log('Search error: $e');
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _OrdersList(
              userId: authProvider.userId!,
              orderType: OrderListType.active,
            ),
            _OrdersList(
              userId: authProvider.userId!,
              orderType: OrderListType.completed,
            ),
            _OrdersList(
              userId: authProvider.userId!,
              orderType: OrderListType.rejected,
            ),
          ],
        ),
      ),
    );
  }
}

enum OrderListType { active, completed, rejected }

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
              return order.status == OrderStatus.pending ||
                  order.status == OrderStatus.approved ||
                  order.status == OrderStatus.preparing ||
                  order.status == OrderStatus.ready;
            case OrderListType.completed:
              return order.status == OrderStatus.completed;
            case OrderListType.rejected:
              return order.status == OrderStatus.rejected;
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
    }
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text('Order #${order.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${order.status.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                color: _getStatusColor(order.status),
              ),
            ),
            Text(
              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
        children: [
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
    }
  }
}

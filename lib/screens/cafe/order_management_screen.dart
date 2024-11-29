import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../utils/search_delegates.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  @override
  void dispose() {
    // Cancel any active operations
    super.dispose();
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus status) async {
    if (!mounted) return; // Add mounted check

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(orderId, status);

      if (!mounted) return; // Add mounted check before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated')),
      );
    } catch (e) {
      if (!mounted) return; // Add mounted check before showing error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Order Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendingOrdersList(cafeId: authProvider.userId!),
            _OrderList(
              cafeId: authProvider.userId!,
              orderType: OrderListType.active,
            ),
            _OrderList(
              cafeId: authProvider.userId!,
              orderType: OrderListType.completed,
            ),
            _OrderList(
              cafeId: authProvider.userId!,
              orderType: OrderListType.rejected,
            ),
          ],
        ),
      ),
    );
  }
}

enum OrderListType { active, completed, rejected }

class _PendingOrdersList extends StatelessWidget {
  final String cafeId;

  const _PendingOrdersList({required this.cafeId});

  @override
  Widget build(BuildContext context) {
    if (cafeId.isEmpty) {
      return const Center(child: Text('Invalid cafe ID'));
    }

    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context).streamPendingOrders(cafeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // log('Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error loading orders'),
                Text('Details: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<OrderProvider>(context, listen: false)
                        .notifyListeners();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];
        // log('Pending orders count: ${orders.length}');

        if (orders.isEmpty) {
          return const Center(child: Text('No pending orders'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final order = orders[i];
            return PendingOrderCard(order: order);
          },
        );
      },
    );
  }
}

class PendingOrderCard extends StatelessWidget {
  final Order order;

  const PendingOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Order #${order.id.substring(0, 8)}'),
            subtitle: Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
            trailing: const Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              final item = order.items[index];
              return ListTile(
                title: Text(item.name),
                trailing: Text('${item.quantity}x \$${item.price}'),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _acceptOrder(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _showRejectDialog(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context) async {
    try {
      await Provider.of<OrderProvider>(context, listen: false)
          .updateOrderStatus(order.id, OrderStatus.approved);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting order: $e')),
      );
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    await showRejectOrderDialog(
      context,
      order.id,
      (reason) async {
        await Provider.of<OrderProvider>(context, listen: false)
            .updateOrderStatus(
          order.id,
          OrderStatus.rejected,
          rejectionReason: reason,
        );
      },
    );
  }
}

Future<void> showRejectOrderDialog(
  BuildContext context,
  String orderId,
  Function(String) onReject,
) async {
  final reasonController = TextEditingController();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                await onReject(reason);

                // Always close the dialog first, then show the snackbar
                Navigator.of(dialogContext).pop();

                if (context.mounted) {
                  reasonController.dispose();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Order rejected successfully')),
                  );
                }
              } catch (e) {
                log('Error rejecting order: $e');
                if (context.mounted) {
                  // Close the dialog even if there's an error
                  Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting order: $e')),
                  );
                }
              }
            },
            child: const Text('Reject Order'),
          ),
        ],
      ),
    ),
  );
}

class _OrderList extends StatelessWidget {
  final String cafeId;
  final OrderListType orderType;

  const _OrderList({
    required this.cafeId,
    required this.orderType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context).streamCafeOrders(cafeId),
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
              return order.status == OrderStatus.approved ||
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
          itemBuilder: (ctx, i) => CafeOrderCard(order: orders[i]),
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

class CafeOrderCard extends StatelessWidget {
  final Order order;

  const CafeOrderCard({super.key, required this.order});

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
          if (order.status == OrderStatus.pending)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(
                      context,
                      order.id,
                      OrderStatus.approved,
                    ),
                    child: const Text('Accept'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _showRejectDialog(context, order.id),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ),
          if (order.status == OrderStatus.approved)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(
                  context,
                  order.id,
                  OrderStatus.preparing,
                ),
                child: const Text('Start Preparing'),
              ),
            ),
          if (order.status == OrderStatus.preparing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(
                  context,
                  order.id,
                  OrderStatus.ready,
                ),
                child: const Text('Mark as Ready'),
              ),
            ),
          if (order.status == OrderStatus.ready)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(
                  context,
                  order.id,
                  OrderStatus.completed,
                ),
                child: const Text('Mark as Completed'),
              ),
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

  void _updateOrderStatus(
    BuildContext context,
    String orderId,
    OrderStatus status,
  ) {
    Provider.of<OrderProvider>(context, listen: false)
        .updateOrderStatus(orderId, status);
  }

  void _showRejectDialog(BuildContext context, String orderId) {
    showRejectOrderDialog(
      context,
      orderId,
      (reason) async {
        await Provider.of<OrderProvider>(context, listen: false)
            .updateOrderStatus(
          orderId,
          OrderStatus.rejected,
          rejectionReason: reason,
        );
      },
    );
  }
}

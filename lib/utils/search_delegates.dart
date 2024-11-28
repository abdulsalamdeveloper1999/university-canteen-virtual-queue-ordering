import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class MenuSearchDelegate extends SearchDelegate<MenuItem?> {
  final List<MenuItem> menuItems;

  MenuSearchDelegate(this.menuItems);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = menuItems.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('${item.category} - \$${item.price}'),
          trailing: Text(
            item.queueCount > 0 ? 'Queue: ${item.queueCount}' : 'Available',
            style: TextStyle(
              color: item.queueCount > 0 ? Colors.orange : Colors.green,
            ),
          ),
          onTap: () {
            close(context, item);
          },
        );
      },
    );
  }
}

class OrderSearchDelegate extends SearchDelegate<Order?> {
  final List<Order> orders;

  OrderSearchDelegate(this.orders);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = orders.where((order) {
      final orderItems =
          order.items.map((item) => item.name.toLowerCase()).join(' ');
      final status = order.status.toString().split('.').last.toLowerCase();
      final searchQuery = query.toLowerCase();

      return orderItems.contains(searchQuery) ||
          status.contains(searchQuery) ||
          order.id.toLowerCase().contains(searchQuery);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final order = results[index];
        return ListTile(
          title: Text('Order #${order.id.substring(0, 8)}'),
          subtitle: Text(
            'Status: ${order.status.toString().split('.').last} - \$${order.totalAmount}',
          ),
          onTap: () {
            close(context, order);
          },
        );
      },
    );
  }
}

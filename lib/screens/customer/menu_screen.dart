import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';
import '../../utils/search_delegates.dart';
import '../../widgets/category_filter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategory;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Fetch menu items for all cafes
      Provider.of<MenuProvider>(context, listen: false).fetchAllMenuItems();
      _isInitialized = true;
    }
  }

  List<MenuItem> _filterMenuItems(List<MenuItem> items) {
    if (_selectedCategory == null) return items;
    return items.where((item) => item.category == _selectedCategory).toList();
  }

  List<String> _getCategories(List<MenuItem> items) {
    return items.map((item) => item.category).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = _getCategories(menuProvider.menuItems);
        final filteredItems = _filterMenuItems(menuProvider.menuItems);

        return Scaffold(
          appBar: AppBar(
            // backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: const Text('Menu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  try {
                    final MenuItem? result = await showSearch<MenuItem?>(
                      context: context,
                      delegate: MenuSearchDelegate(menuProvider.menuItems),
                    );
                    if (result != null && mounted) {
                      Provider.of<CartProvider>(context, listen: false)
                          .addItem(result);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item added to cart'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    log('Search error: $e');
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              CategoryFilter(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text('No menu items available'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return MenuItemCard(item: item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Image Container
          if (item.imageUrl != null)
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white.withOpacity(0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Item Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      item.queueCount > 0
                          ? 'Queue: ${item.queueCount}'
                          : 'Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add to Cart Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              onPressed: () {
                context.read<CartProvider>().addItem(item);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Item added to cart'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        context.read<CartProvider>().removeItem(item.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

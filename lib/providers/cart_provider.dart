import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items.update(
        menuItem.id,
        (existingItem) => CartItem(
          menuItem: existingItem.menuItem,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        menuItem.id,
        () => CartItem(menuItem: menuItem),
      );
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (!_items.containsKey(menuItemId)) return;
    if (quantity <= 0) {
      removeItem(menuItemId);
    } else {
      _items.update(
        menuItemId,
        (existingItem) => CartItem(
          menuItem: existingItem.menuItem,
          quantity: quantity,
        ),
      );
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool hasItems() {
    return _items.isNotEmpty;
  }

  int getQuantity(String menuItemId) {
    return _items[menuItemId]?.quantity ?? 0;
  }
}

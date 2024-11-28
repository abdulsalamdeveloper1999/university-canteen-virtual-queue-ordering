enum OrderStatus { pending, approved, preparing, ready, completed, rejected }

class Order {
  final String id;
  final String customerId;
  final String cafeId;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final double totalAmount;
  final String? rejectionReason;

  Order({
    required this.id,
    required this.customerId,
    required this.cafeId,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    this.rejectionReason,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // print('Parsing order JSON: $json');
    final statusStr = json['status'] as String;
    final status = OrderStatus.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );

    return Order(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      cafeId: json['cafeId'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: status,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final statusStr = status.toString().split('.').last.toLowerCase();
    // print('Converting order to JSON with status: $statusStr');

    return {
      'id': id,
      'customerId': customerId,
      'cafeId': cafeId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': statusStr,
      'createdAt': createdAt.toIso8601String(),
      'totalAmount': totalAmount,
      'rejectionReason': rejectionReason,
    };
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

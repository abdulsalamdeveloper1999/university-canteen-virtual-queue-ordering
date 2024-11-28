class MenuItem {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final int queueCount;
  final String category;
  final String cafeId;
  final Map<String, int> orderQuantities;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.queueCount,
    required this.category,
    required this.cafeId,
    Map<String, int>? orderQuantities,
    this.imageUrl,
  }) : orderQuantities = orderQuantities ?? {};

  MenuItem copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
    int? queueCount,
    String? category,
    String? cafeId,
    Map<String, int>? orderQuantities,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      queueCount: queueCount ?? this.queueCount,
      category: category ?? this.category,
      cafeId: cafeId ?? this.cafeId,
      orderQuantities: orderQuantities ?? this.orderQuantities,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool,
      queueCount: json['queueCount'] as int,
      category: json['category'] as String,
      cafeId: json['cafeId'] as String,
      orderQuantities: Map<String, int>.from(json['orderQuantities'] ?? {}),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'queueCount': queueCount,
      'category': category,
      'cafeId': cafeId,
      'orderQuantities': orderQuantities,
      'imageUrl': imageUrl,
    };
  }
}

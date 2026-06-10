class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['product_id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap(String orderId) {
    return {
      "order_id": orderId,
      "product_id": productId,
      "price": price,
      "quantity": quantity,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String phone;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.phone,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> itemsData,
  ) {
    return OrderModel(
      id: map['id'],
      userId: map['user_id'] ?? '',
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      phone: map['phone'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      items: itemsData.map((e) => OrderItemModel.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "total_amount": totalAmount,
      "status": status,
      "phone": phone,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    double? totalAmount,
    String? status,
    String? phone,
    DateTime? createdAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
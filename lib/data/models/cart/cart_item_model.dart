class CartItemModel {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    final product = map['products'] ?? {};

    return CartItemModel(
      id: map['id'],
      productId: product['id'] ?? '',
      name: product['name'] ?? '',
      price: (product['price'] ?? 0).toDouble(),
      imageUrl: product['image_url'],
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "product_id": productId,
      "quantity": quantity,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}
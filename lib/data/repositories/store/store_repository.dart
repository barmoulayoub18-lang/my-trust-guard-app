import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = "products/$fileName.jpg";

    await supabase.storage.from('images').upload(path, file);

    final publicUrl = supabase.storage.from('images').getPublicUrl(path);
    return publicUrl;
  }

  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
  }) async {
    await supabase.from('products').insert({
      "name": name,
      "description": description,
      "price": price,
      "image_url": imageUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getCart() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('cart_items')
        .select('id, quantity, products(*)')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addToCart(String productId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('cart_items')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await supabase
          .from('cart_items')
          .update({
            "quantity": (existing['quantity'] ?? 1) + 1,
          })
          .eq('id', existing['id']);
    } else {
      await supabase.from('cart_items').insert({
        "user_id": user.id,
        "product_id": productId,
        "quantity": 1,
      });
    }
  }

  Future<void> updateQuantity({
    required String cartId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(cartId);
      return;
    }

    await supabase
        .from('cart_items')
        .update({"quantity": quantity})
        .eq('id', cartId);
  }

  Future<void> removeFromCart(String cartId) async {
    await supabase.from('cart_items').delete().eq('id', cartId);
  }

  Future<void> clearCart() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('cart_items').delete().eq('user_id', user.id);
  }

  double calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0;

    for (var item in items) {
      final product = item['products'];
      final price = product['price'] ?? 0;
      final qty = item['quantity'] ?? 1;
      total += price * qty;
    }

    return total;
  }

  Future<String> createOrder({
    required double total,
    required String phone,
  }) async {
    final user = supabase.auth.currentUser;

    final order = await supabase.from('orders').insert({
      "user_id": user?.id,
      "total_amount": total,
      "phone": phone,
    }).select().single();

    return order['id'];
  }

  Future<void> addOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    required double price,
  }) async {
    await supabase.from('order_items').insert({
      "order_id": orderId,
      "product_id": productId,
      "quantity": quantity,
      "price": price,
    });
  }
}
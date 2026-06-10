import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/store/store_repository.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final repo = StoreRepository();

  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    setState(() => isLoading = true);

    try {
      final data = await repo.getCart();
      cartItems = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      showMessage("Error loading cart");
    }

    setState(() => isLoading = false);
  }

  Future<void> removeItem(String id) async {
    await repo.removeFromCart(id);
    fetchCart();
  }

  Future<void> increaseQty(Map<String, dynamic> item) async {
    try {
      await repo.addToCart(item['products']['id']);
      fetchCart();
    } catch (e) {
      showMessage("Error updating quantity");
    }
  }

  Future<void> decreaseQty(Map<String, dynamic> item) async {
    final qty = item['quantity'] ?? 1;

    if (qty <= 1) {
      await removeItem(item['id']);
      return;
    }

    try {
      await repo.updateQuantity(
        cartId: item['id'],
        quantity: qty - 1,
      );
      fetchCart();
    } catch (e) {
      showMessage("Error updating quantity");
    }
  }

  double getTotal() {
    return repo.calculateTotal(cartItems);
  }

  Future<void> sendToWhatsApp() async {
    if (cartItems.isEmpty) {
      showMessage("Cart is empty");
      return;
    }

    String message = "طلب جديد:\n\n";

    for (var item in cartItems) {
      final product = item['products'];
      final name = product['name'];
      final price = product['price'];
      final qty = item['quantity'];

      message += "$name\n";
      message += "الكمية: $qty\n";
      message += "السعر: $price\n\n";
    }

    message += "الإجمالي: ${getTotal()}";

    final url =
        "https://wa.me/213542389397?text=${Uri.encodeComponent(message)}";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showMessage("Cannot open WhatsApp");
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> refresh() async {
    await fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartItems.isEmpty
                ? const Center(child: Text("Cart is empty"))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final product = item['products'];

                            return ListTile(
                              leading: Image.network(
                                product['image_url'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                              title: Text(product['name']),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text("${product['price']}"),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () =>
                                            decreaseQty(item),
                                      ),
                                      Text("${item['quantity']}"),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () =>
                                            increaseQty(item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  removeItem(item['id']);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${getTotal()}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: sendToWhatsApp,
                                child: const Text("Order via WhatsApp"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
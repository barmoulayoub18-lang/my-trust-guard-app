import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final supabase = Supabase.instance.client;

  List cartItems = [];
  bool isLoading = true;

  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await supabase
          .from('cart_items')
          .select('id, quantity, products(*)')
          .eq('user_id', user.id);

      cartItems = data;
    } catch (e) {
      showMessage("Error loading cart");
    }

    setState(() => isLoading = false);
  }

  double getTotal() {
    double total = 0;

    for (var item in cartItems) {
      final product = item['products'];
      final price = product['price'] ?? 0;
      final qty = item['quantity'] ?? 1;
      total += price * qty;
    }

    return total;
  }

  Future<void> placeOrder() async {
    if (cartItems.isEmpty) {
      showMessage("Cart is empty");
      return;
    }

    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMessage("Enter phone number");
      return;
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        showMessage("You must login first");
        return;
      }

      final order = await supabase.from('orders').insert({
        "user_id": user.id,
        "total_amount": getTotal(),
        "phone": phone,
      }).select().single();

      final orderId = order['id'];

      for (var item in cartItems) {
        final product = item['products'];

        await supabase.from('order_items').insert({
          "order_id": orderId,
          "product_id": product['id'],
          "quantity": item['quantity'],
          "price": product['price'],
        });
      }

      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);

      await sendToWhatsApp();

      if (!mounted) return;

      showMessage("Order placed successfully");

      Navigator.pop(context);
    } catch (e) {
      showMessage("Error placing order");
    }
  }

  Future<void> sendToWhatsApp() async {
    String message = "طلب جديد:\n\n";

    for (var item in cartItems) {
      final product = item['products'];

      message += "${product['name']}\n";
      message += "الكمية: ${item['quantity']}\n";
      message += "السعر: ${product['price']}\n\n";
    }

    message += "الإجمالي: ${getTotal()}";

    final url =
        "https://wa.me/213542389397?text=${Uri.encodeComponent(message)}";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text("Cart is empty"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final product = item['products'];

                            return ListTile(
                              title: Text(product['name']),
                              subtitle: Text(
                                "Qty: ${item['quantity']} - ${product['price']}",
                              ),
                            );
                          },
                        ),
                      ),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
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
                          onPressed: placeOrder,
                          child: const Text("Confirm Order"),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
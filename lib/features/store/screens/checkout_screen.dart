import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../presentation/widgets/custom_card.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final supabase = Supabase.instance.client;
  bool isPlacingOrder = false;
  final phoneController = TextEditingController();

  Future<void> placeOrder(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    print("========== بدء عملية إتمام الطلب ==========");
    
    if (cartItems.isEmpty) {
      print("[فشل] السلة فارغة لا يمكن إتمام الطلب.");
      showMessage("Cart is empty");
      return;
    }

    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      print("[فشل] رقم الهاتف فارغ.");
      showMessage("Enter phone number");
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      print("[فشل] المستخدم لم يقم بتسجيل الدخول.");
      showMessage("You must login first");
      return;
    }

    setState(() => isPlacingOrder = true);

    try {
      print("[1/5] جاري إدخال الطلب الرئيسي في جدول 'orders' بقيمة: $totalAmount...");
      final order = await supabase.from('orders').insert({
        "user_id": user.id,
        "total_amount": totalAmount,
        "phone": phone,
      }).select().single();

      final orderId = order['id'];
      print("[نجاح] تم إنشاء الطلب بنجاح، رقم معرف الطلب (Order ID): $orderId");

      print("[2/5] جاري تجهيز عناصر الطلب لجدول 'order_items'...");
      final List<Map<String, dynamic>> orderItemsInsert = [];
      for (var item in cartItems) {
        final product = item['products'];
        orderItemsInsert.add({
          "order_id": orderId,
          "product_id": product['id'],
          "quantity": item['quantity'],
          "price": product['price'],
        });
      }

      if (orderItemsInsert.isNotEmpty) {
        print("جاري رفع عدد ${orderItemsInsert.length} من العناصر إلى 'order_items'...");
        await supabase.from('order_items').insert(orderItemsInsert);
        print("[نجاح] تم إدخال كل عناصر الطلب بنجاح.");
      }

      print("[3/5] جاري حذف عناصر السلة من قاعدة البيانات (Supabase)...");
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);
      print("[نجاح] تم إفراغ السلة من Supabase.");

      print("[4/5] جاري تحديث حالة التطبيق المحلية وتصفير السلة عبر Riverpod...");
      await ref.read(cartProvider.notifier).adjustItemsAfterOrder();
      print("[نجاح] تم تصفير السلة محلياً بنجاح.");

      print("[5/5] جاري محاولة إرسال الطلب عبر WhatsApp وفتح التطبيق...");
      await sendToWhatsApp(cartItems, totalAmount);

      if (!mounted) return;

      showMessage("Order placed successfully");
      print("========== تمت العملية بالكامل بنجاح ==========");

      Navigator.pop(context);
    } catch (e) {
      print("[خطأ فادح أثناء إتمام الطلب]: $e");
      showMessage("Error placing order");
    } finally {
      if (mounted) {
        setState(() => isPlacingOrder = false);
      }
    }
  }

  Future<void> sendToWhatsApp(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    print("--- بدء تجهيز رسالة الـ WhatsApp ---");
    String message = "طلب جديد:\n\n";

    for (var item in cartItems) {
      final product = item['products'];
      message += "${product['name']}\n";
      message += "الكمية: ${item['quantity']}\n";
      message += "السعر: ${product['price']}\n\n";
    }

    message += "الإجمالي: $totalAmount";

    final url = "https://wa.me/213542389397?text=${Uri.encodeComponent(message)}";
    print("الرابط الذي تم إنشاؤه: $url");

    try {
      final uri = Uri.parse(url);
      print("جاري محاولة فتح الرابط مباشرة بوضع التطبيق الخارجي...");
      
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      print("نتيجة launchUrl (هل تم الفتح بنجاح؟): $launched");
      if (!launched) {
        print("[تحذير] لم يتمكن النظام من فتح الرابط (قد لا يكون التطبيق مثبتاً أو الرابط غير مدعوم).");
      }
    } catch (whatsappError) {
      print("[خطأ استثنائي أثناء تشغيل الواتساب]: $whatsappError");
    }
    print("--- انتهاء محاولة تشغيل الـ WhatsApp ---");
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState.items;
    final totalAmount = cartState.total;
    final isLoading = cartState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Cart is empty",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final product = item['products'];

                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 400 + (index * 50)),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 15 * (1.0 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: CustomCard(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    title: Text(
                                      product['name'],
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Qty: ${item['quantity']} × \$${double.tryParse(product['price'].toString())?.toStringAsFixed(2) ?? product['price']}",
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    trailing: Text(
                                      "\$${((double.tryParse(product['price'].toString()) ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1.0 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                enabled: !isPlacingOrder,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: "Phone Number",
                                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  floatingLabelStyle: const TextStyle(color: AppColors.primary),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total Amount",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    "\$${totalAmount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isPlacingOrder ? null : () => placeOrder(cartItems, totalAmount),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textPrimary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                child: isPlacingOrder
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text("Confirm Order"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
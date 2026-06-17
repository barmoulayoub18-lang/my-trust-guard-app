import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
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

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    if (!mounted) return;
    print("[جلب السلة] جاري تحميل عناصر السلة من المستودع...");
    setState(() => isLoading = true);

    try {
      final data = await repo.getCart();
      cartItems = List<Map<String, dynamic>>.from(data);
      print("[جلب السلة] تم جلب البيانات بنجاح. عدد العناصر في السلة: ${cartItems.length}");
    } catch (e) {
      print("[خطأ في جلب السلة]: $e");
      showMessage("Error loading cart");
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> removeItem(String id) async {
    print("[حذف عنصر] جاري حذف العنصر ذو المعرف (ID): $id...");
    await repo.removeFromCart(id);
    print("[حذف عنصر] تم الحذف بنجاح، جاري تحديث السلة...");
    fetchCart();
  }

  Future<void> increaseQty(Map<String, dynamic> item) async {
    final productId = item['products']['id'];
    print("[زيادة الكمية] جاري إضافة المنتج (Product ID: $productId) لزيادة الكمية...");
    try {
      await repo.addToCart(productId);
      print("[زيادة الكمية] تم التحديث بنجاح، جاري إعادة جلب السلة...");
      fetchCart();
    } catch (e) {
      print("[خطأ في زيادة الكمية]: $e");
      showMessage("Error updating quantity");
    }
  }

  Future<void> decreaseQty(Map<String, dynamic> item) async {
    final qty = item['quantity'] ?? 1;
    print("[إنقاص الكمية] الكمية الحالية هي: $qty");

    if (qty <= 1) {
      print("[إنقاص الكمية] الكمية أقل من أو تساوي 1، جاري تحويل العملية إلى حذف العنصر بالكامل...");
      await removeItem(item['id']);
      return;
    }

    try {
      print("[إنقاص الكمية] جاري تحديث الكمية لتصبح: ${qty - 1} للعنصر: ${item['id']}...");
      await repo.updateQuantity(
        cartId: item['id'],
        quantity: qty - 1,
      );
      print("[إنقاص الكمية] تم إنقاص الكمية بنجاح، جاري إعادة جلب السلة...");
      fetchCart();
    } catch (e) {
      print("[خطأ في إنقاص الكمية]: $e");
      showMessage("Error updating quantity");
    }
  }

  double getTotal() {
    return repo.calculateTotal(cartItems);
  }

  void showOrderDetailsDialog() {
    print("[طلب] محاولة فتح نافذة تفاصيل التوصيل...");
    if (cartItems.isEmpty) {
      print("[فشل] لا يمكن فتح النافذة لأن السلة فارغة.");
      showMessage("Cart is empty");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Delivery Details",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Delivery Address",
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print("[طلب] تم إلغاء عملية إدخال تفاصيل التوصيل من قبل المستخدم.");
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();

                print("[طلب] تم الضغط على Confirm. البيانات المدخلة: الاسم='$name', الهاتف='$phone', العنوان='$address'");

                if (name.isEmpty || phone.isEmpty || address.isEmpty) {
                  print("[طلب] فشل التحقق: توجد حقول فارغة لم يتم ملؤها.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                print("[طلب] نجح التحقق من الحقول، إغلاق النافذة وبدء معالجة الواتساب...");
                Navigator.pop(context);
                sendToWhatsApp(name: name, phone: phone, address: address);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendToWhatsApp({
    required String name,
    required String phone,
    required String address,
  }) async {
    print("========== بدء معالجة رسالة الـ WhatsApp ==========");
    String message = "طلب جديد عبر الواتساب\n";
    message += "=========================\n";
    message += "الاسم الكامل: $name\n";
    message += "رقم الهاتف: $phone\n";
    message += "عنوان التوصيل: $address\n";
    message += "=========================\n\n";
    message += "المنتجات:\n";

    print("جاري صياغة نص المنتجات المشحونة (عدد المنتجات: ${cartItems.length})...");
    for (var item in cartItems) {
      final product = item['products'];
      final pName = product['name'];
      final price = product['price'];
      final qty = item['quantity'];

      message += "- $pName\n";
      message += "   الكمية: $qty × \$$price\n\n";
    }

    message += "=========================\n";
    message += "الإجمالي: \$${getTotal()}";

    final String fallbackUrl = "https://wa.me/213542389397?text=${Uri.encodeComponent(message)}";
    final Uri fallbackUri = Uri.parse(fallbackUrl);
    print("الرابط النهائي لـ WhatsApp هو: $fallbackUrl");

    try {
      print("جاري محاولة فتح تطبيق الواتساب مباشرة عبر الوضع الخارجي لضمان تخطي حظر الحماية...");
      final launchResult = await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );
      
      print("نتيجة استدعاء launchUrl المباشر: $launchResult");
      
      if (launchResult) {
        print("[نجاح] تم فتح الواتساب بنجاح، جاري الانتقال لتفريغ السلة...");
        await clearCartAfterOrder();
      } else {
        print("[تحذير] لم يفتح النظام الرابط مباشرة، محاولة الفتح بالوضع الافتراضي كخيار احتياطي أخير...");
        final fallbackLaunch = await launchUrl(fallbackUri);
        if (fallbackLaunch) {
          await clearCartAfterOrder();
        } else {
          print("[خطأ] فشلت جميع محاولات فتح الرابط الخارجي.");
          showMessage("Cannot open WhatsApp");
        }
      }
    } catch (e) {
      print("[خطأ استثنائي تم التقاطه بنجاح لمنع الانهيار]: $e");
      showMessage("Error opening WhatsApp");
    }
    print("========== انتهاء معالجة عملية الـ WhatsApp ==========");
  }

  Future<void> clearCartAfterOrder() async {
    if (!mounted) return;
    print("[إفراغ السلة بعد الطلب] بدء عملية إفراغ السلة وتنظيف الحقول...");
    setState(() => isLoading = true);

    try {
      final currentItems = List<Map<String, dynamic>>.from(cartItems);
      print("[إفراغ السلة بعد الطلب] جاري حذف عدد ${currentItems.length} عنصر من قاعدة البيانات...");
      
      for (var item in currentItems) {
        print("جاري حذف العنصر ذو المعرف database-id: ${item['id']}...");
        await repo.removeFromCart(item['id']);
      }
      
      print("[إفراغ السلة بعد الطلب] تم حذف العناصر من قاعدة البيانات بنجاح، جاري تصفير الحقول النصية...");
      nameController.clear();
      phoneController.clear();
      addressController.clear();
      
      print("[إفراغ السلة بعد الطلب] جاري تحديث واجهة السلة محلياً...");
      await fetchCart();
      showMessage("Order sent and cart cleared successfully");
    } catch (e) {
      print("[خطأ أثناء إفراغ السلة]: $e");
      showMessage("Order sent, but failed to clear cart database");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> refresh() async {
    print("[تحديث يدوي] جاري سحب الشاشة لتحديث بيانات السلة...");
    await fetchCart();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Cart",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: const Color(0xFF3B82F6),
        backgroundColor: Colors.white,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  strokeWidth: 3,
                ),
              )
            : cartItems.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Center(
                        child: Text(
                          "Cart is empty",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 350),
                          tween: Tween<double>(begin: 0.96, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: child,
                            );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              final product = item['products'];
                              final imageUrl = product['image_url'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: imageUrl == null
                                            ? Container(
                                                width: 75,
                                                height: 75,
                                                color: const Color(0xFFF1F5F9),
                                                child: const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: Color(0xFF94A3B8),
                                                  size: 28,
                                                ),
                                              )
                                            : Image.network(
                                                imageUrl,
                                                width: 75,
                                                height: 75,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "\$${product['price'] ?? 0}",
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(Icons.remove, size: 16, color: Color(0xFF475569)),
                                                    onPressed: () => decreaseQty(item),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                  child: Text(
                                                    "${item['quantity'] ?? 1}",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF475569)),
                                                    onPressed: () => increaseQty(item),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        alignment: Alignment.topRight,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                                        onPressed: () => removeItem(item['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                          border: const Border(
                            top: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    "\$${getTotal()}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: showOrderDetailsDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Order via WhatsApp",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
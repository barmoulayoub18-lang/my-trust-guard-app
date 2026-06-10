import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/loading_widget.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final storeController = TextEditingController();
  final amountController = TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // =====================================================
  // 📦 LOAD TRANSACTIONS
  // =====================================================
  Future<void> loadTransactions() async {
    try {
      final user = SupabaseService.currentUser;

      if (user == null) return;

      final data = await SupabaseService.client
          .from('transactions')
          .select()
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        transactions = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      Helpers.showSnackBar(context, "Error loading transactions", isError: true);
    }
  }

  // =====================================================
  // 💳 CREATE PAYMENT
  // =====================================================
  Future<void> createPayment() async {
    final store = storeController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (store.isEmpty || amount == null) {
      Helpers.showSnackBar(context, "Invalid data", isError: true);
      return;
    }

    try {
      setState(() => isLoading = true);

      await SupabaseService.createTransaction(
        storeId: store,
        amount: amount,
      );

      Helpers.showSnackBar(context, "Payment secured successfully ✅");

      storeController.clear();
      amountController.clear();

      await loadTransactions();
    } catch (e) {
      Helpers.showSnackBar(context, "Payment failed", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // =====================================================
  // 🔄 UPDATE STATUS
  // =====================================================
  Future<void> updateStatus(String id, String status) async {
    try {
      await SupabaseService.client
          .from('transactions')
          .update({'status': status})
          .eq('id', id);

      await loadTransactions();
    } catch (e) {
      Helpers.showSnackBar(context, "Update failed", isError: true);
    }
  }

  // =====================================================
  // 🎨 STATUS COLOR
  // =====================================================
  Color getStatusColor(String status) {
    switch (status) {
      case "released":
        return AppColors.success;
      case "refunded":
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  // =====================================================
  // 🧱 UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // 🔐 HEADER
                CustomCard(
                  gradient: AppColors.primaryGradient,
                  child: Row(
                    children: const [
                      Icon(Icons.lock, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Your money is protected until you confirm delivery",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 💳 FORM
                CustomCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: storeController,
                        decoration: const InputDecoration(
                          labelText: "Store ID or Name",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Amount (\$)",
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomButton(
                        text: "Secure Payment",
                        icon: Icons.security,
                        isLoading: isLoading,
                        onPressed: createPayment,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 📋 TITLE
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Transactions",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 10),

                // 📦 LIST
                transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 60,
                                color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 10),
                            Text(
                              "No transactions yet",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactions.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = transactions[index];

                          final status =
                              (item['status'] ?? "pending").toString();

                          final store =
                              (item['store_id'] ?? "Unknown").toString();

                          final amount =
                              (item['amount'] ?? 0).toString();

                          final id = (item['id'] ?? "").toString();

                          return CustomCard(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // 🏪 STORE
                                Text(
                                  store,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // 💰 AMOUNT
                                Text(
                                  "\$$amount",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // STATUS + ACTIONS
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(status)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    if (status == "pending" && id.isNotEmpty)
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                updateStatus(id, "released"),
                                            child: const Text("Release"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                updateStatus(id, "refunded"),
                                            child: const Text("Refund"),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),

          // ⏳ LOADING
          if (isLoading)
            const LoadingWidget(
              isFullScreen: true,
              text: "Processing payment...",
            ),
        ],
      ),
    );
  }
}
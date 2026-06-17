import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/supabase_service.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/loading_widget.dart';
import 'escrow_actions_widget.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final WalletRepository _walletRepo = WalletRepository();
  final storeController = TextEditingController();
  final amountController = TextEditingController();
  final memoController = TextEditingController();

  bool isLoading = false;
  double availableBalance = 0.00;
  double frozenBalance = 0.00;
  String selectedFilter = 'All';
  
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> demoAccounts = [];
  Map<String, dynamic>? selectedDemoAccount;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    await Future.wait([
      loadWalletBalances(),
      loadTransactions(),
      _loadDemoAccounts(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> loadWalletBalances() async {
    try {
      final balances = await _walletRepo.getUserWalletBalances();
      setState(() {
        availableBalance = double.tryParse(balances['available_balance'].toString()) ?? 0.00;
        frozenBalance = double.tryParse(balances['frozen_balance'].toString()) ?? 0.00;
      });
    } catch (e) {
      Helpers.showSnackBar(context, "Error loading wallet balance", isError: true);
    }
  }

  Future<void> loadTransactions() async {
    try {
      final data = await _walletRepo.getStandaloneEscrowTransactions();
      setState(() {
        transactions = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      try {
        final user = SupabaseService.currentUser;
        if (user == null) return;
        final fallbackData = await SupabaseService.client
            .from('transactions')
            .select()
            .eq('buyer_id', user.id)
            .order('created_at', ascending: false);
        setState(() {
          transactions = List<Map<String, dynamic>>.from(fallbackData);
        });
      } catch (err) {
        Helpers.showSnackBar(context, "Error loading transactions", isError: true);
      }
    }
  }

  Future<void> _loadDemoAccounts() async {
    try {
      final accounts = await _walletRepo.getEscrowDemoAccounts();
      setState(() {
        demoAccounts = accounts;
        if (demoAccounts.isNotEmpty) {
          selectedDemoAccount = demoAccounts.first;
          storeController.text = demoAccounts.first['account_tag'] ?? '';
        }
      });
    } catch (_) {}
  }

  Future<void> _handleSandboxTopup() async {
    setState(() => isLoading = true);
    try {
      await _walletRepo.executeSandboxTopup(500.00);
      Helpers.showSnackBar(context, "Sandbox Top-Up successful (+\$500.00)");
      await loadWalletBalances();
    } catch (e) {
      Helpers.showSnackBar(context, "Top-Up failed", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createPayment() async {
    final store = storeController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    final memo = memoController.text.trim().isEmpty ? "P2P Secure Contract Hold" : memoController.text.trim();

    if (store.isEmpty || amount == null || amount <= 0) {
      Helpers.showSnackBar(context, "Invalid data structure", isError: true);
      return;
    }

    if (amount > availableBalance) {
      Helpers.showSnackBar(context, "Insufficient funds in available balance", isError: true);
      return;
    }

    try {
      setState(() => isLoading = true);

      try {
        await _walletRepo.executeStandaloneEscrowHold(
          amount: amount,
          memo: memo,
          demoRecipientTag: store,
        );
      } catch (err) {
        await SupabaseService.createTransaction(
          storeId: store,
          amount: amount,
        );
      }

      Helpers.showSnackBar(context, "Payment secured successfully");

      amountController.clear();
      memoController.clear();

      await Future.wait([
        loadWalletBalances(),
        loadTransactions(),
      ]);
    } catch (e) {
      Helpers.showSnackBar(context, "Payment processing failed", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      setState(() => isLoading = true);
      if (status == "released") {
        await _walletRepo.executeStandaloneRelease(id);
      } else if (status == "refunded" || status == "disputed") {
        await _walletRepo.executeStandaloneRefund(id);
      } else {
        await SupabaseService.client
            .from('transactions')
            .update({'status': status})
            .eq('id', id);
      }

      await Future.wait([
        loadWalletBalances(),
        loadTransactions(),
      ]);
    } catch (e) {
      try {
        await SupabaseService.client
            .from('transactions')
            .update({'status': status})
            .eq('id', id);
        await Future.wait([
          loadWalletBalances(),
          loadTransactions(),
        ]);
      } catch (err) {
        Helpers.showSnackBar(context, "Update state mutation failed", isError: true);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "released":
      case "completed":
        return AppColors.success;
      case "refunded":
      case "disputed":
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    if (selectedFilter == 'All') return transactions;
    return transactions.where((tx) {
      final status = (tx['status'] ?? tx['escrow_status'] ?? 'pending').toString().toLowerCase();
      if (selectedFilter == 'Active Holds') return status == 'pending';
      if (selectedFilter == 'Completed') return status == 'released' || status == 'completed';
      if (selectedFilter == 'Disputed') return status == 'refunded' || status == 'disputed';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTx = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Secure P2P Protocol",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _initializeData,
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "AVAILABLE BALANCE",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "\$${availableBalance.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "FROZEN IN ESCROW",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "\$${frozenBalance.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(color: AppColors.border, height: 1),
                          ),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _handleSandboxTopup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                            label: const Text("Sandbox Top-Up (+\$500.00)"),
                          ),
                        ],
                      ),
                    ),
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
                        offset: Offset(0, 20 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomCard(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your money is protected until you confirm safe delivery",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (demoAccounts.isNotEmpty) ...[
                          Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: AppColors.surface,
                            ),
                            child: DropdownButtonFormField<Map<String, dynamic>>(
                              value: selectedDemoAccount,
                              isExpanded: true,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: "Select Verified Recipient",
                                labelStyle: const TextStyle(color: AppColors.textSecondary),
                                filled: true,
                                fillColor: AppColors.background.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              items: demoAccounts.map((account) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: account,
                                  child: Text(
                                    "${account['display_name']} (${account['account_tag']})",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedDemoAccount = val;
                                    storeController.text = val['account_tag'] ?? '';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: storeController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Recipient Account Tag / ID",
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.person_pin_rounded, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.background.withOpacity(0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Hold Amount (\$)",
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.background.withOpacity(0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: memoController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Contract Memo / Purpose",
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.description_rounded, color: AppColors.textSecondary),
                            hintText: "e.g., Freelance Logo Design, Laptop Buy",
                            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 13),
                            filled: true,
                            fillColor: AppColors.background.withOpacity(0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: "Initiate Secure Protocol",
                          icon: Icons.security_rounded,
                          isLoading: isLoading,
                          onPressed: createPayment,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Escrow Ledger",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedFilter,
                      underline: const SizedBox(),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      items: <String>['All', 'Active Holds', 'Completed', 'Disputed'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedFilter = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                filteredTx.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 40, bottom: 40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              "No matching transactions in sandbox",
                              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTx.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = filteredTx[index];
                          final status = (item['status'] ?? item['escrow_status'] ?? "pending").toString();
                          final store = (item['store_id'] ?? item['demo_recipient_tag'] ?? "Unknown").toString();
                          final amountRaw = double.tryParse(item['amount'].toString()) ?? 0.0;
                          final id = (item['id'] ?? "").toString();
                          final memo = (item['memo'] ?? "Independent Escrow Hold Ledger").toString();

                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, val, child) {
                              return Opacity(
                                opacity: val,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1.0 - val)),
                                  child: child,
                                ),
                              );
                            },
                            child: CustomCard(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        store,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        "\$${amountRaw.toStringAsFixed(2)}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Memo: $memo",
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      if (status.toLowerCase() == "pending" && id.isNotEmpty)
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () => updateStatus(id, "released"),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.success,
                                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              child: const Text("Release"),
                                            ),
                                            const SizedBox(width: 4),
                                            TextButton(
                                              onPressed: () => updateStatus(id, "refunded"),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.danger,
                                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              child: const Text("Refund"),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (status.toLowerCase() == "pending" && id.isNotEmpty) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(color: AppColors.border, height: 1),
                                    ),
                                    EscrowActionsWidget(
                                      orderId: id,
                                      amount: amountRaw,
                                      currentEscrowStatus: status,
                                      onStateMutated: () async {
                                        await Future.wait([
                                          loadWalletBalances(),
                                          loadTransactions(),
                                        ]);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          if (isLoading)
            const LoadingWidget(
              isFullScreen: true,
              text: "Synchronizing security architecture...",
            ),
        ],
      ),
    );
  }
}
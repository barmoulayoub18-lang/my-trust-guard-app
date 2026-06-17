import 'package:flutter/material.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/wallet_model.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/loading_widget.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletRepository _repo = WalletRepository();
  bool _isLoading = true;
  WalletModel? _wallet;
  List<Map<String, dynamic>> _txns = [];

  @override
  void initState() {
    super.initState();
    _loadWalletMetrics();
  }

  Future<void> _loadWalletMetrics() async {
    setState(() => _isLoading = true);
    try {
      final w = await _repo.fetchUserWallet();
      final t = await _repo.fetchWalletTransactions();
      setState(() {
        _wallet = w;
        _txns = t;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleQuickTopup() async {
    setState(() => _isLoading = true);
    try {
      await _repo.executeSandboxTopup(500.00);
      Helpers.showSnackBar(context, "FinTech Sandbox Wallet Credited (+\$500.00)");
      await _loadWalletMetrics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Top-Up Mutation failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Escrow FinTech Wallet',
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
            icon: const Icon(Icons.sync_alt_rounded, color: AppColors.textSecondary),
            onPressed: _loadWalletMetrics,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: _loadWalletMetrics,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                      child: _buildBalanceCard(),
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
                      child: ElevatedButton.icon(
                        onPressed: _handleQuickTopup,
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
                          ),
                        ),
                        icon: const Icon(Icons.add_card_rounded, size: 18),
                        label: const Text('Sandbox Liquidity Injection (+\$500.00)'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Escrow Ledger Bookings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_txns.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No historical ledger records found.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._txns.asMap().entries.map((entry) {
                        final index = entry.key;
                        final t = entry.value;

                        Color typeColor;
                        IconData typeIcon;
                        final String transactionType =
                            t['type']?.toString().toLowerCase() ?? '';

                        if (transactionType == 'release' ||
                            transactionType == 'refund' ||
                            transactionType == 'topup' ||
                            transactionType == 'deposit') {
                          typeColor = AppColors.success;
                          typeIcon = Icons.arrow_downward_rounded;
                        } else if (transactionType == 'hold') {
                          typeColor = AppColors.warning;
                          typeIcon = Icons.lock_clock_rounded;
                        } else {
                          typeColor = AppColors.textSecondary;
                          typeIcon = Icons.payment_rounded;
                        }

                        final double amt =
                            double.tryParse(t['amount'].toString()) ?? 0.00;

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + (index * 50)),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: val,
                              child: Transform.translate(
                                offset: Offset(0, 15 * (1.0 - val)),
                                child: child,
                              ),
                            );
                          },
                          child: CustomCard(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(typeIcon, color: typeColor, size: 20),
                              ),
                              title: Text(
                                t['description'] ?? 'Transaction Record',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  t['type'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: typeColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                '${amt.toStringAsFixed(2)} USD',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            const Text(
              'AVAILABLE CLEAR BALANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_wallet?.availableBalance.toStringAsFixed(2) ?? "0.00"} USD',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.border, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Escrow Frozen Hold',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_wallet?.frozenBalance.toStringAsFixed(2) ?? "0.00"} USD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Total Net Balance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${((_wallet?.availableBalance ?? 0.0) + (_wallet?.frozenBalance ?? 0.0)).toStringAsFixed(2)} USD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
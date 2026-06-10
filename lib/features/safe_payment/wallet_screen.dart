import 'package:flutter/material.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/wallet_model.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/loading_widget.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escrow FinTech Wallet')),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: _loadWalletMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    const Text('Escrow Ledger Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_txns.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('No historical ledger records found.', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ..._txns.map((t) {
                        Color typeColor;
                        IconData typeIcon;
                        final String transactionType = t['type']?.toString().toLowerCase() ?? '';
                        
                        if (transactionType == 'release' || transactionType == 'refund') {
                          typeColor = Colors.green;
                          typeIcon = Icons.arrow_downward;
                        } else if (transactionType == 'hold') {
                          typeColor = Colors.orange;
                          typeIcon = Icons.lock_clock;
                        } else {
                          typeColor = Colors.blueGrey;
                          typeIcon = Icons.payment;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: typeColor.withOpacity(0.1),
                              child: Icon(typeIcon, color: typeColor, size: 20),
                            ),
                            title: Text(t['description'] ?? 'Transaction Record'),
                            subtitle: Text(t['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            trailing: Text(
                              '${t['amount']} USD',
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text('AVAILABLE CLEAR BALANCE', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('${_wallet?.availableBalance.toStringAsFixed(2) ?? "0.00"} USD', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Escrow Frozen Hold', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('${_wallet?.frozenBalance.toStringAsFixed(2) ?? "0.00"} USD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Total Net Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('${((_wallet?.availableBalance ?? 0.0) + (_wallet?.frozenBalance ?? 0.0)).toStringAsFixed(2)} USD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
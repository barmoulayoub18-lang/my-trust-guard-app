import 'package:flutter/material.dart';
import '../../data/repositories/wallet_repository.dart';

class EscrowActionsWidget extends StatefulWidget {
  final String orderId;
  final double amount;
  final String currentEscrowStatus;
  final VoidCallback onStateMutated;

  const EscrowActionsWidget({
    super.key,
    required this.orderId,
    required this.amount,
    required this.currentEscrowStatus,
    required this.onStateMutated,
  });

  @override
  State<EscrowActionsWidget> createState() => _EscrowActionsWidgetState();
}

class _EscrowActionsWidgetState extends State<EscrowActionsWidget> {
  final WalletRepository _walletRepo = WalletRepository();
  bool _isProcessing = false;

  Future<void> _handleRelease() async {
    setState(() => _isProcessing = true);
    try {
      await _walletRepo.executeReleaseFunds(widget.orderId, widget.amount);
      widget.onStateMutated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mutation error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDispute() async {
    setState(() => _isProcessing = true);
    try {
      await _walletRepo.executeRefundFunds(widget.orderId, widget.amount);
      widget.onStateMutated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mutation error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentEscrowStatus != 'pending') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Escrow Status Security Lock: ${widget.currentEscrowStatus.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escrow Protection Ledger Active: Funds (${widget.amount.toStringAsFixed(2)}) are securely retained in system vault.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleRelease,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Confirm Receipt'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _handleDispute,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red),
                  child: const Text('File Trade Dispute'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
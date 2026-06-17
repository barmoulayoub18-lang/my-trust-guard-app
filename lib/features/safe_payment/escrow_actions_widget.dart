import 'package:flutter/material.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../core/constants/colors.dart';

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
      await _walletRepo.executeStandaloneRelease(widget.orderId);
      widget.onStateMutated();
    } catch (e) {
      try {
        await _walletRepo.executeReleaseFunds(widget.orderId, widget.amount);
        widget.onStateMutated();
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mutation error: $err'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDispute() async {
    setState(() => _isProcessing = true);
    try {
      await _walletRepo.executeStandaloneRefund(widget.orderId);
      widget.onStateMutated();
    } catch (e) {
      try {
        await _walletRepo.executeRefundFunds(widget.orderId, widget.amount);
        widget.onStateMutated();
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mutation error: $err'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentEscrowStatus != 'pending') {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Escrow Status Security Lock: ${widget.currentEscrowStatus.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escrow Protection Ledger Active: Funds (${widget.amount.toStringAsFixed(2)}) are securely retained in system vault.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleRelease,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.success.withOpacity(0.5),
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
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Confirm Receipt'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _handleDispute,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger, width: 1.5),
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    child: const Text('File Trade Dispute'),
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
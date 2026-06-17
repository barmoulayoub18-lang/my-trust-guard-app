import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<WalletModel> fetchUserWallet() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Authentication needed");

    final data = await _client
        .from('wallets')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (data == null) {
      final freshWallet = await _client.from('wallets').insert({
        'user_id': user.id,
        'available_balance': 0.00,
        'frozen_balance': 0.00
      }).select().single();
      return WalletModel.fromJson(freshWallet);
    }
    return WalletModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> fetchWalletTransactions() async {
    final wallet = await fetchUserWallet();
    final data = await _client
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', wallet.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> confirmEscrowDelivery(String orderId) async {
    await _client.from('orders').update({
      'escrow_status': 'released',
      'status': 'completed'
    }).eq('id', orderId);
  }

  Future<void> triggerEscrowDispute(String orderId) async {
    await _client.from('orders').update({
      'escrow_status': 'disputed',
      'status': 'disputed'
    }).eq('id', orderId);
  }

  Future<void> createEscrowHold(String orderId, double amount) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Authentication needed");

    final wallet = await fetchUserWallet();
    if (wallet.availableBalance < amount) {
      throw Exception("Insufficient available balance for escrow hold");
    }

    await _client.from('wallets').update({
      'available_balance': wallet.availableBalance - amount,
      'frozen_balance': wallet.frozenBalance + amount,
    }).eq('id', wallet.id);

    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'amount': amount,
      'type': 'hold',
      'description': 'Funds frozen securely in escrow for order #$orderId'
    });

    await _client.from('orders').update({
      'escrow_status': 'pending',
    }).eq('id', orderId);
  }

  Future<void> executeReleaseFunds(String orderId, double amount) async {
    final wallet = await fetchUserWallet();
    
    await _client.from('wallets').update({
      'frozen_balance': wallet.frozenBalance - amount >= 0 ? wallet.frozenBalance - amount : 0.0,
    }).eq('id', wallet.id);

    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'amount': amount,
      'type': 'release',
      'description': 'Escrow cleared and disbursed safely for order #$orderId'
    });

    await confirmEscrowDelivery(orderId);
  }

  Future<void> executeRefundFunds(String orderId, double amount) async {
    final wallet = await fetchUserWallet();

    await _client.from('wallets').update({
      'frozen_balance': wallet.frozenBalance - amount >= 0 ? wallet.frozenBalance - amount : 0.0,
      'available_balance': wallet.availableBalance + amount,
    }).eq('id', wallet.id);

    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'amount': amount,
      'type': 'refund',
      'description': 'Escrow disputed funds returned to available balance for order #$orderId'
    });

    await triggerEscrowDispute(orderId);
  }

  Future<Map<String, dynamic>> getUserWalletBalances() async {
    try {
      return await SupabaseService.fetchUserWalletBalances();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getWalletHistoryLogs() async {
    try {
      return await SupabaseService.fetchWalletHistoryLogs();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getStandaloneEscrowTransactions() async {
    try {
      return await SupabaseService.fetchStandaloneEscrowTransactions();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getEscrowDemoAccounts() async {
    try {
      return await SupabaseService.fetchEscrowDemoAccounts();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> executeSandboxTopup(double amount) async {
    try {
      await SupabaseService.triggerSandboxTopup(amount);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> executeStandaloneEscrowHold({
    required double amount,
    required String memo,
    required String demoRecipientTag,
  }) async {
    try {
      return await SupabaseService.triggerStandaloneEscrowHold(
        amount: amount,
        memo: memo,
        demoRecipientTag: demoRecipientTag,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> executeStandaloneRelease(String transactionId) async {
    try {
      await SupabaseService.triggerStandaloneRelease(transactionId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> executeStandaloneRefund(String transactionId) async {
    try {
      await SupabaseService.triggerStandaloneRefund(transactionId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
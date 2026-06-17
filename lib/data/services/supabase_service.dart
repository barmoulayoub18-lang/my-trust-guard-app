import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    _client = Supabase.instance.client;

    final session = _client!.auth.currentSession;

    if (session != null) {
      try {
        await _client!.auth.refreshSession();
      } catch (_) {
        await _client!.auth.signOut();
      }
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception("Supabase not initialized");
    }
    return _client!;
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static Stream get authState => client.auth.onAuthStateChange;

  static Future sendOtp(String email) async {
    return;
  }

  static Future verifyOtp({
    required String email,
    required String token,
  }) async {
    return;
  }

  static Future signUp({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signUp(
        email: email,
        password: password,
      );
      await createProfileIfNotExists();
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future signIn({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signOut();

      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception("Invalid credentials");
      }

      await createProfileIfNotExists();
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future signOut() async {
    await client.auth.signOut();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final data = await client.from('profiles').select().eq('id', user.id).single();

    return data;
  }

  static Future saveAnalysis({
    required String storeId,
    required double score,
    required Map<String, dynamic> details,
  }) async {
    final user = currentUser;

    await client.from('analysis_results').insert({
      'user_id': user?.id,
      'store_id': storeId,
      'score': score,
      'risk_level': details['risk'],
      'details': details,
    });
  }

  static Future<List<Map<String, dynamic>>> getUserAnalyses() async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('analysis_results')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future addComplaint({
    required String storeId,
    required String reason,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    await client.from('complaints').insert({
      'store_id': storeId,
      'user_id': user.id,
      'reason': reason,
      'status': 'pending',
    });
  }

  static Future<List<Map<String, dynamic>>> getComplaints() async {
    final data = await client
        .from('complaints')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future addReview({
    required String storeId,
    required int rating,
    String? comment,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    await client.from('reviews').insert({
      'store_id': storeId,
      'user_id': user.id,
      'rating': rating,
      'comment': comment,
    });
  }

  static Future createTransaction({
    required String storeId,
    required double amount,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    await client.from('transactions').insert({
      'store_id': storeId,
      'buyer_id': user.id,
      'amount': amount,
    });
  }

  static Future uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = "products/$fileName.jpg";

    await client.storage.from('images').upload(path, file);

    final url = client.storage.from('images').getPublicUrl(path);
    return url;
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await client
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
  }) async {
    await client.from('products').insert({
      "name": name,
      "description": description,
      "price": price,
      "image_url": imageUrl,
    });
  }

  static Future<List<Map<String, dynamic>>> getCart() async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('cart_items')
        .select('id, quantity, products(*)')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future addToCart(String productId) async {
    final user = currentUser;
    if (user == null) return;

    final existing = await client
        .from('cart_items')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('cart_items')
          .update({
            "quantity": (existing['quantity'] ?? 1) + 1,
          })
          .eq('id', existing['id']);
    } else {
      await client.from('cart_items').insert({
        "user_id": user.id,
        "product_id": productId,
        "quantity": 1,
      });
    }
  }

  static Future removeFromCart(String cartId) async {
    await client.from('cart_items').delete().eq('id', cartId);
  }

  static Future clearCart() async {
    final user = currentUser;
    if (user == null) return;

    await client.from('cart_items').delete().eq('user_id', user.id);
  }

  static Future createOrder({
    required double total,
    required String phone,
  }) async {
    final user = currentUser;

    final order = await client.from('orders').insert({
      "user_id": user?.id,
      "total_amount": total,
      "phone": phone,
    }).select().single();

    return order['id'];
  }

  static Future addOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    required double price,
  }) async {
    await client.from('order_items').insert({
      "order_id": orderId,
      "product_id": productId,
      "quantity": quantity,
      "price": price,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchEscrowDemoAccounts() async {
    final data = await client.from('escrow_demo_accounts').select().order('display_name');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> fetchUserWalletBalances() async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final data = await client.from('wallets').select().eq('user_id', user.id).maybeSingle();
    if (data == null) {
      final fresh = await client.from('wallets').insert({
        'user_id': user.id,
        'available_balance': 0.00,
        'frozen_balance': 0.00,
      }).select().single();
      return fresh;
    }
    return data;
  }

  static Future<List<Map<String, dynamic>>> fetchWalletHistoryLogs() async {
    final user = currentUser;
    if (user == null) return [];

    final wallet = await client.from('wallets').select('id').eq('user_id', user.id).maybeSingle();
    if (wallet == null) return [];

    final data = await client
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', wallet['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchStandaloneEscrowTransactions() async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('transactions')
        .select()
        .eq('buyer_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future triggerSandboxTopup(double amount) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    await client.rpc('execute_sandbox_topup', params: {
      'target_user_id': user.id,
      'amount_to_add': amount,
    });
  }

  static Future triggerStandaloneEscrowHold({
    required double amount,
    required String memo,
    required String demoRecipientTag,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final res = await client.rpc('create_standalone_escrow_hold', params: {
      'buyer_id_param': user.id,
      'amount_param': amount,
      'memo_param': memo,
      'demo_recipient_tag': demoRecipientTag,
    });
    return res.toString();
  }

  static Future triggerStandaloneRelease(String transactionId) async {
    await client.rpc('execute_standalone_release', params: {
      'transaction_id_param': transactionId,
    });
  }

  static Future triggerStandaloneRefund(String transactionId) async {
    await client.rpc('execute_standalone_refund', params: {
      'transaction_id_param': transactionId,
    });
  }

  static Exception _handleError(Object e) {
    final msg = e.toString();

    if (msg.contains('Invalid login credentials')) {
      return Exception("Email or password is incorrect");
    }

    if (msg.contains('Email not confirmed')) {
      return Exception("Please verify your email first");
    }

    if (msg.contains('User already registered')) {
      return Exception("Email already exists");
    }

    if (msg.contains('network') || msg.contains('SocketException')) {
      return Exception("Check your internet connection");
    }

    if (msg.contains('timeout')) {
      return Exception("Request timeout");
    }

    return Exception(msg);
  }

  static Future createProfileIfNotExists() async {
    final user = currentUser;
    if (user == null) return;

    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await client.from('profiles').insert({
        'id': user.id,
        'name': user.email?.split('@').first ?? 'User',
        'avatar_url': null,
        'role': 'user',
      });
    }
  }
}
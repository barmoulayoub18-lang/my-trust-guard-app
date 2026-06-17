import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/store/store_repository.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.read(storeRepositoryProvider));
});

class CartNotifier extends StateNotifier<CartState> {
  final StoreRepository repository;

  CartNotifier(this.repository) : super(CartState.initial());

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);

    try {
      final items = await repository.getCart();
      final total = repository.calculateTotal(items);

      state = state.copyWith(
        items: List<Map<String, dynamic>>.from(items),
        total: total,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Error loading cart",
      );
    }
  }

  Future<void> refresh() async {
    await loadCart();
  }

  Future<void> add(String productId) async {
    await repository.addToCart(productId);
    await loadCart();
  }

  Future<void> remove(String cartId) async {
    await repository.removeFromCart(cartId);
    await loadCart();
  }

  Future<void> adjustItemsAfterOrder() async {
    state = CartState.initial();
  }

  Future<void> increase(String productId) async {
    await repository.addToCart(productId);
    await loadCart();
  }

  Future<void> decrease({
    required String cartId,
    required int currentQty,
  }) async {
    if (currentQty <= 1) {
      await repository.removeFromCart(cartId);
    } else {
      await repository.updateQuantity(
        cartId: cartId,
        quantity: currentQty - 1,
      );
    }

    await loadCart();
  }

  Future<void> clear() async {
    state = state.copyWith(isLoading: true);
    try {
      final currentItems = List<Map<String, dynamic>>.from(state.items);
      for (var item in currentItems) {
        await repository.removeFromCart(item['id']);
      }
      state = CartState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Error clearing cart",
      );
    }
  }
}

class CartState {
  final List<Map<String, dynamic>> items;
  final double total;
  final bool isLoading;
  final String? error;

  CartState({
    required this.items,
    required this.total,
    required this.isLoading,
    this.error,
  });

  factory CartState.initial() {
    return CartState(
      items: [],
      total: 0,
      isLoading: false,
      error: null,
    );
  }

  CartState copyWith({
    List<Map<String, dynamic>>? items,
    double? total,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
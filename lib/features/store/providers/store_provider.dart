import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/store/store_repository.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

final storeProvider =
    StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  final notifier = StoreNotifier(ref.read(storeRepositoryProvider));
  Future.microtask(() => notifier.loadProducts());
  return notifier;
});

class StoreNotifier extends StateNotifier<StoreState> {
  final StoreRepository repository;

  StoreNotifier(this.repository) : super(StoreState.initial());

  Future<void> loadProducts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await repository.getProducts();
      state = state.copyWith(
        products: List<Map<String, dynamic>>.from(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Error loading products",
      );
    }
  }

  Future<void> refresh() async {
    await loadProducts();
  }
}

class StoreState {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final String? error;

  StoreState({
    required this.products,
    required this.isLoading,
    this.error,
  });

  factory StoreState.initial() {
    return StoreState(
      products: [],
      isLoading: false,
      error: null,
    );
  }

  StoreState copyWith({
    List<Map<String, dynamic>>? products,
    bool? isLoading,
    String? error,
  }) {
    return StoreState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
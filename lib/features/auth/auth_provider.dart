import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_service.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription? _authSub;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    final user = SupabaseService.currentUser;

    state = state.copyWith(user: user);

    _authSub?.cancel();
    _authSub = SupabaseService.authState.listen((data) {
      final session = data.session;

      if (!mounted) return;

      state = state.copyWith(
        user: session?.user,
      );
    });
  }

  Future<void> sendOtp(String email) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await SupabaseService.sendOtp(email);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await SupabaseService.verifyOtp(
        email: email,
        token: code,
      );

      state = state.copyWith(
        isLoading: false,
        user: SupabaseService.currentUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Invalid or expired code",
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await SupabaseService.signUp(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        user: SupabaseService.currentUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await SupabaseService.signIn(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        user: SupabaseService.currentUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Email or password is incorrect",
      );
    }
  }

  Future<bool> checkAdmin({
    required String email,
    required String password,
  }) async {
    if (email == "admin@gmail.com" && password == "admin0") {
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await SupabaseService.signOut();

    state = state.copyWith(
      clearUser: true,
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
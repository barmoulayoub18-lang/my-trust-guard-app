import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/supabase_service.dart';
import '../auth/auth_provider.dart';

// =====================================================
// 📊 PROFILE STATE
// =====================================================
class ProfileState {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    Map<String, dynamic>? profile,
    String? error,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: clearProfile ? null : (profile ?? this.profile),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// =====================================================
// 🧠 PROFILE NOTIFIER
// =====================================================
class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(const ProfileState()) {
    _listenAuth();
  }

  // =====================================================
  // 🔄 ربط البروفايل مع تسجيل الدخول
  // =====================================================
  void _listenAuth() {
    ref.listen<AuthState>(authProvider, (prev, next) {
      // ❌ تسجيل خروج
      if (next.user == null) {
        state = const ProfileState();
      }

      // ✅ تسجيل دخول
      if (next.user != null && prev?.user == null) {
        loadProfile();
      }
    });
  }

  // =====================================================
  // 📥 LOAD PROFILE
  // =====================================================
  Future<void> loadProfile() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      state = state.copyWith(isLoading: true, clearError: true);

      final data = await SupabaseService.getProfile();

      state = state.copyWith(
        isLoading: false,
        profile: data,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // =====================================================
  // ✏️ UPDATE PROFILE
  // =====================================================
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception("User not logged in");

      state = state.copyWith(isLoading: true, clearError: true);

      await SupabaseService.client.from('profiles').update({
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', user.id);

      // 🔄 إعادة تحميل
      await loadProfile();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to update profile",
      );
    }
  }

  // =====================================================
  // 🔄 CLEAR
  // =====================================================
  void clear() {
    state = const ProfileState();
  }
}

// =====================================================
// 🌐 PROVIDER
// =====================================================
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);
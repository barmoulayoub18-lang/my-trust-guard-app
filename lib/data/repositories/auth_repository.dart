import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  static Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await SupabaseService.createProfileIfNotExists();
        return null;
      } else {
        return "Sign up failed";
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await SupabaseService.createProfileIfNotExists();
        return null;
      } else {
        return "Invalid credentials";
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  static dynamic getCurrentUser() {
    return SupabaseService.client.auth.currentUser;
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<bool> isAdmin({
    required String email,
    required String password,
  }) async {
    if (email == "admin@gmail.com" && password == "admin0") {
      return true;
    }
    return false;
  }

  static Future<String?> updatePassword(String newPassword) async {
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<String?> updateEmail(String newEmail) async {
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  static String _handleError(Object e) {
    final msg = e.toString();

    if (msg.contains('Invalid login credentials')) {
      return "Email or password is incorrect";
    }

    if (msg.contains('Email not confirmed')) {
      return "Please verify your email first";
    }

    if (msg.contains('User already registered')) {
      return "Email already exists";
    }

    if (msg.contains('network') || msg.contains('SocketException')) {
      return "Check your internet connection";
    }

    if (msg.contains('timeout')) {
      return "Request timeout";
    }

    return msg;
  }
}
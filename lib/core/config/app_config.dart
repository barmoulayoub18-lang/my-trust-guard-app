import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String appName = "trust_guard_app";
  static const String version = "1.0.0";

  static String get environment => dotenv.env['ENV'] ?? "development";

  static bool get isProduction => environment == "production";
  static bool get isDebug => !isProduction;

  static String get backendUrl {
    final url = dotenv.env['BACKEND_URL'];

    if (url == null || url.isEmpty) {
      throw Exception("❌ BACKEND_URL is missing in .env");
    }

    if (!url.startsWith("http")) {
      throw Exception("❌ BACKEND_URL is invalid");
    }

    return url;
  }

  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception("❌ SUPABASE_URL is missing");
    }

    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (key == null || key.isEmpty) {
      throw Exception("❌ SUPABASE_ANON_KEY is missing");
    }

    return key;
  }

  static String get aiBaseUrl =>
      dotenv.env['AI_BASE_URL'] ?? "https://openrouter.ai/api/v1";

  static String get aiApiKey {
    final key = dotenv.env['AI_API_KEY'];

    if (key == null || key.isEmpty) {
      throw Exception("❌ AI_API_KEY missing");
    }

    return key;
  }

  static String get aiModel =>
      dotenv.env['AI_MODEL'] ?? "meta-llama/llama-3-8b-instruct";

  static Map<String, String> get aiHeaders => {
        "Authorization": "Bearer $aiApiKey",
        "Content-Type": "application/json",
        "HTTP-Referer": "trust_guard_app",
        "X-Title": appName,
      };

  static const Duration apiTimeout = Duration(seconds: 60);

  static String getEnv(String key, {String? fallback}) {
    final value = dotenv.env[key];

    if (value == null || value.isEmpty) {
      if (fallback != null) return fallback;
      throw Exception("❌ Missing env variable: $key");
    }

    return value;
  }

  static bool get enableAuth => (dotenv.env['ENABLE_AUTH'] ?? "true") == "true";

  static bool get enableEmailVerification =>
      (dotenv.env['ENABLE_EMAIL_VERIFICATION'] ?? "false") == "true";
}

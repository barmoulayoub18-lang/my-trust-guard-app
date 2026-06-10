import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class ApiService {
  ApiService._();

  // =====================================================
  // 🌐 DIO INSTANCE (PRODUCTION READY)
  // =====================================================
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.backendUrl, // ✅ الصحيح
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {
        "Content-Type": "application/json",
      },
    ),
  )
    ..interceptors.add(
      LogInterceptor(
        request: AppConfig.isDebug,
        requestBody: AppConfig.isDebug,
        responseBody: AppConfig.isDebug,
        error: true,
      ),
    );

  // =====================================================
  // 🧠 ANALYZE STORE
  // =====================================================
  static Future<Map<String, dynamic>> analyze(String query) async {
    try {
      final response = await _dio.post(
        "/analyze",
        data: {"query": query},
      );

      // ✅ تحقق من الرد
      if (response.statusCode != 200) {
        throw Exception("Server error (${response.statusCode})");
      }

      final data = response.data;

      if (data == null) {
        throw Exception("Empty response from server");
      }

      // 🔥 السيرفر قد يرجع String أو Map
      final raw = data["data"];
      final parsed =
          (raw is String) ? jsonDecode(raw) : raw;

      if (parsed is! Map) {
        throw Exception("Invalid response format");
      }

      return Map<String, dynamic>.from(parsed);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // =====================================================
  // 🔁 SAFE REQUEST (اختياري للتوسعة)
  // =====================================================
  static Future<Response> _safePost(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // =====================================================
  // ⚠️ ERROR HANDLER (احترافي جدا)
  // =====================================================
  static String _handleError(DioException e) {
    // 🔴 Server responded
    if (e.response != null) {
      final status = e.response?.statusCode;
      final message = e.response?.data.toString();

      return "Server error ($status)\n$message";
    }

    // ⏳ Timeout
    if (e.type == DioExceptionType.connectionTimeout) {
      return "Connection timeout. Server not responding.";
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return "Server is slow. Try again.";
    }

    // 🌐 No internet / wrong URL
    if (e.type == DioExceptionType.connectionError) {
      return "Cannot connect to server.\nCheck WiFi or backend URL.";
    }

    // ❌ Cancel
    if (e.type == DioExceptionType.cancel) {
      return "Request cancelled";
    }

    // ❌ Unknown
    return "Network error: ${e.message}";
  }
}
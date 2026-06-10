import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  // =====================================================
  // 🔑 API KEY
  // =====================================================
  static String get _apiKey {
    final key = dotenv.env['SERPER_KEY'] ?? "";
    if (key.isEmpty) {
      throw Exception("❌ SERPER_KEY missing in .env");
    }
    return key;
  }

  // =====================================================
  // 🔎 GOOGLE SEARCH (RAW DATA)
  // =====================================================
  static Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await _dio.post(
        "https://google.serper.dev/search",
        options: Options(
          headers: {
            "X-API-KEY": _apiKey,
            "Content-Type": "application/json",
          },
        ),
        data: {
          "q": query,
          "gl": "us",
          "hl": "en",
          "num": 10,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception("Search failed: $e");
    }
  }

  // =====================================================
  // 🔥 SMART STORE SEARCH (الأهم)
  // =====================================================
  static Future<Map<String, dynamic>> searchStore(String input) async {
    try {
      // 🔍 بحث شامل
      final searchData = await search(
        "$input reviews trustpilot scam rating site:trustpilot.com OR site:reddit.com OR site:facebook.com",
      );

      return {
        "organic": extractOrganic(searchData),
        "questions": extractQuestions(searchData),
      };
    } catch (e) {
      throw Exception("Store search failed: $e");
    }
  }

  // =====================================================
  // 📄 CLEAN ORGANIC RESULTS
  // =====================================================
  static List<Map<String, String>> extractOrganic(
      Map<String, dynamic> data) {
    final List items = data['organic'] ?? [];

    return items.take(8).map<Map<String, String>>((item) {
      return {
        "title": item['title']?.toString() ?? "",
        "snippet": item['snippet']?.toString() ?? "",
        "link": item['link']?.toString() ?? "",
      };
    }).toList();
  }

  // =====================================================
  // ❓ QUESTIONS
  // =====================================================
  static List<String> extractQuestions(Map<String, dynamic> data) {
    final List items = data['peopleAlsoAsk'] ?? [];

    return items
        .take(5)
        .map<String>((q) => q['question']?.toString() ?? "")
        .toList();
  }

  // =====================================================
  // ⚠️ ERROR HANDLER
  // =====================================================
  static String _handleError(DioException e) {
    if (e.response != null) {
      return "API Error ${e.response?.statusCode}";
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return "Connection timeout";
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return "Server timeout";
    }

    return "Network error";
  }
}
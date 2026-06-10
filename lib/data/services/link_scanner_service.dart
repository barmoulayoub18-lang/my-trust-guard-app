import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class LinkScannerService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.backendUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  static Future<Map<String, dynamic>> scanUrl(String targetUrl) async {
    try {
      final response = await _dio.post(
        "/scan-link",
        data: {"url": targetUrl},
      );
      if (response.statusCode == 200 && response.data != null) {
        final responseMap = Map<String, dynamic>.from(response.data);
        if (responseMap['success'] == true && responseMap['data'] != null) {
          return Map<String, dynamic>.from(responseMap['data']);
        }
        return responseMap;
      }
      throw Exception("Invalid backend scanner response structure");
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorMap = Map<String, dynamic>.from(e.response!.data);
        if (errorMap['error'] != null) {
          throw Exception(errorMap['error'].toString());
        }
      }
      throw Exception(e.response?.data?.toString() ?? "Network failure running scanner engine");
    } catch (e) {
      throw Exception("Unexpected scanning execution error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchGlobalPhishingFeeds() async {
    try {
      final response = await _dio.get("/phishing-feed");
      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class AIService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.aiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: AppConfig.aiHeaders,
    ),
  );

  static Future<String> chat(String message) async {
    try {
      print("========== AI REQUEST START ==========");
      print("Base URL: ${AppConfig.aiBaseUrl}");
      print("Model: ${AppConfig.aiModel}");
      print("Headers: ${AppConfig.aiHeaders}");
      print("Message: $message");

      final body = {
        "model": AppConfig.aiModel,
        "temperature": 0.7,
        "messages": [
          {
            "role": "system",
            "content":
                "You are a smart assistant helping users shop safely. Be helpful, short, and clear."
          },
          {
            "role": "user",
            "content": message,
          }
        ],
      };

      print("Request Body:");
      print(body);

      final response = await _dio.post(
        "/chat/completions",
        data: body,
      );

      print("Status Code: ${response.statusCode}");
      print("Raw Response:");
      print(response.data);

      final data = response.data;

      String? content;

      print("Parsing response...");

      if (data != null && data["choices"] != null) {
        final choices = data["choices"];
        print("Choices found: ${choices.length}");

        if (choices is List && choices.isNotEmpty) {
          final first = choices[0];
          print("First choice: $first");

          if (first["message"] != null &&
              first["message"]["content"] != null) {
            content = first["message"]["content"];
            print("Content extracted from message");
          } else if (first["text"] != null) {
            content = first["text"];
            print("Content extracted from text");
          }
        }
      } else {
        print("No choices in response");
      }

      if (content == null || content.toString().trim().isEmpty) {
        print("ERROR: Empty AI response");
        throw Exception("Empty AI response");
      }

      print("Final AI Response:");
      print(content);
      print("========== AI REQUEST END ==========");

      return content.toString().trim();
    } on DioException catch (e) {
      print("========== DIO ERROR ==========");
      print("Error Type: ${e.type}");
      print("Error Message: ${e.message}");

      if (e.response != null) {
        print("Status Code: ${e.response?.statusCode}");
        print("Response Data: ${e.response?.data}");

        final err = e.response?.data;

        if (err is Map && err["error"] != null) {
          print("Parsed Error: ${err["error"]}");
          return "⚠️ ${err["error"]["message"] ?? "AI error"}";
        }
      }

      print("========== END ERROR ==========");
      return "⚠️ Network error. Try again.";
    } catch (e) {
      print("========== UNKNOWN ERROR ==========");
      print(e.toString());
      print("========== END ERROR ==========");
      return "⚠️ AI is not available now. Try again.";
    }
  }
}
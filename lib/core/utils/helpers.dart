import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';

class Helpers {
  Helpers._();

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = isError ? const Color(0xFFEF4444) : AppColors.primary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd • HH:mm').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} h ago";
    if (diff.inDays < 7) return "${diff.inDays} d ago";

    return formatDate(date);
  }

  static Color getScoreColor(double score) {
    if (score >= 80) return AppColors.trustHigh;
    if (score >= 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  static Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return AppColors.trustHigh;
      case 'medium':
        return AppColors.trustMedium;
      case 'high':
        return AppColors.trustLow;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String getRiskLabel(double score) {
    if (score >= 80) return "SAFE";
    if (score >= 50) return "CAUTION";
    return "DANGEROUS";
  }

  static String? validateEmail(String value) {
    if (value.trim().isEmpty) return "Email is required";

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) return "Invalid email format";

    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return "Password is required";
    if (value.length < 6) return "Minimum 6 characters";

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Add at least one uppercase letter";
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Add at least one number";
    }

    return null;
  }

  static bool isValidUrl(String text) {
    return Uri.tryParse(text)?.hasAbsolutePath ?? false;
  }

  static double parseDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value.toString()) ?? fallback;
  }

  static void log(dynamic data) {
    debugPrint(data.toString());
  }
}
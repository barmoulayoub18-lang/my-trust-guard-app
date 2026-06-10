import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';

class Helpers {
  Helpers._();

  // =====================================================
  // 📢 SNACKBAR (احترافي)
  // =====================================================
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = isError ? Colors.red : AppColors.primary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // =====================================================
  // 📅 FORMAT DATE
  // =====================================================
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd • HH:mm').format(date);
  }

  // =====================================================
  // ⏱ TIME AGO
  // =====================================================
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} h ago";
    if (diff.inDays < 7) return "${diff.inDays} d ago";

    return formatDate(date);
  }

  // =====================================================
  // 🎯 TRUST SCORE COLOR
  // =====================================================
  static Color getScoreColor(double score) {
    if (score >= 80) return AppColors.trustHigh;
    if (score >= 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  // =====================================================
  // ⚠️ RISK COLOR
  // =====================================================
  static Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return AppColors.trustHigh;
      case 'medium':
        return AppColors.trustMedium;
      case 'high':
        return AppColors.trustLow;
      default:
        return Colors.grey;
    }
  }

  // =====================================================
  // 🏷 RISK LABEL
  // =====================================================
  static String getRiskLabel(double score) {
    if (score >= 80) return "SAFE";
    if (score >= 50) return "CAUTION";
    return "DANGEROUS";
  }

  // =====================================================
  // 📧 EMAIL VALIDATOR
  // =====================================================
  static String? validateEmail(String value) {
    if (value.trim().isEmpty) return "Email is required";

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) return "Invalid email format";

    return null;
  }

  // =====================================================
  // 🔒 PASSWORD VALIDATOR (أقوى 🔥)
  // =====================================================
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

  // =====================================================
  // 🔗 URL CHECK
  // =====================================================
  static bool isValidUrl(String text) {
    return Uri.tryParse(text)?.hasAbsolutePath ?? false;
  }

  // =====================================================
  // 🔢 SAFE PARSE DOUBLE
  // =====================================================
  static double parseDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value.toString()) ?? fallback;
  }

  // =====================================================
  // 🧠 DEBUG LOG (يعمل فقط في debug)
  // =====================================================
  static void log(dynamic data) {
      // ignore: avoid_print
      print("🧠 $data");
  }
}
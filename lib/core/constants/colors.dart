import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // 🎯 PRIMARY (FINTECH BLUE)
  // =========================
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryDark = Color(0xFF1E40AF); // Blue 800
  static const Color primaryLight = Color(0xFF60A5FA); // Blue 400

  // Accent (AI Glow)
  static const Color accent = Color(0xFF22D3EE); // Cyan Glow

  // =========================
  // 🟢 SUCCESS (TRUST)
  // =========================
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFF4ADE80);

  // =========================
  // 🟡 WARNING
  // =========================
  static const Color warning = Color(0xFFF59E0B);

  // =========================
  // 🔴 DANGER
  // =========================
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFF87171);

  // =========================
  // 🌑 DARK THEME (MAIN APP)
  // =========================
  static const Color background = Color(0xFF020617); // Deep black-blue
  static const Color surface = Color(0xFF0F172A); // Cards base
  static const Color card = Color(0xFF111827); // Elevated cards

  // =========================
  // 🧾 TEXT
  // =========================
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // =========================
  // 🧱 BORDERS
  // =========================
  static const Color border = Color(0xFF1F2937);
  static const Color divider = Color(0xFF111827);

  // =========================
  // 🎨 GRADIENTS (PREMIUM)
  // =========================

  // Main App Gradient (Background)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF020617),
      Color(0xFF0F172A),
      Color(0xFF020617),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Primary Button Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF2563EB),
      Color(0xFF22D3EE),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [
      Color(0xFF16A34A),
      Color(0xFF4ADE80),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Danger Gradient
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [
      Color(0xFFDC2626),
      Color(0xFFF87171),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass Effect Overlay
  static const Color glass = Color(0x1FFFFFFF);

  // =========================
  // 🟣 TRUST SCORE COLORS
  // =========================
  static const Color trustHigh = Color(0xFF22C55E);
  static const Color trustMedium = Color(0xFFF59E0B);
  static const Color trustLow = Color(0xFFEF4444);
}
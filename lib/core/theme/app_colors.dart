import 'package:flutter/material.dart';

/// BlueKhata Design System — core palette.
/// Powered by Zenvyro Labs.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF42A5F5);
  static const Color accent = Color(0xFF64B5F6);
  static const Color background = Color(0xFFF5F9FF);
  static const Color darkPrimary = Color(0xFF0D47A1);

  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF10182B);
  static const Color backgroundDark = Color(0xFF0A0F1E);

  static const Color textPrimary = Color(0xFF14213D);
  static const Color textSecondary = Color(0xFF5C6B85);
  static const Color textOnDark = Color(0xFFEAF1FF);
  static const Color divider = Color(0xFFE3EAF6);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x11FFFFFF)],
  );

  // Home dashboard — KHATA / PAYMENTS section tiles.
  // Soft blue tint behind the KHATA grid icons (replaces DigiKhata's peach tint).
  static const Color khataTileBackground = Color(0xFFE3F0FF);

  static const LinearGradient posGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF5E92F3)],
  );

  static const LinearGradient qrGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF2196F3)],
  );

  static const LinearGradient staffBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF102A43), Color(0xFF1565C0)],
  );
}

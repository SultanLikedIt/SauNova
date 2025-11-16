import 'package:flutter/material.dart';

/// saunova Brand Colors
/// saunova Brand Colours
class AppColors {
  // Primary saunova Red
  static const Color primary = Color(0xFFE10600); // vivid saunova red
  static const Color primaryDark = Color(0xFFB20000);
  static const Color primaryLight = Color(0xFFFF4D4D);

  // Neutral / Wood‑tones (for sauna feel)
  static const Color background = Color(
    0xFFF6F2EE,
  ); // warm off‑white / light wood feel
  static const Color surface = Color(0xFFFFFFFF);
  static const Color woodLight = Color(0xFFD9C9B6);
  static const Color woodDark = Color(0xFF8F7A67);

  // Grays / Text
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color grayLight = Color(0xFFE0E0E0);
  static const Color grayDark = Color(0xFF424242);

  // Accents / feedback
  static const Color accent = Color(0xFFFF8A80); // softer red/pink accent
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);

  // Border & subtle UI
  static const Color border = Color(0xFFBDBDBD);
}

extension ColorOpacity on Color {
  Color withOpacityValue(double opacity) => withAlpha((opacity * 255).round());
}

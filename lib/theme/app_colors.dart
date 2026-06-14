import 'package:flutter/material.dart';

/// لوحة ألوان التطبيق - أخضر زمردي هادئ مع لمسات ذهبية فاخرة.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1F6F5C);
  static const Color primaryDark = Color(0xFF154A3D);
  static const Color primaryLight = Color(0xFFE3F2EE);

  /// ذهبي - للعناصر المميزة (التقدّم، السلسلة، الشارات المهجورة).
  static const Color accent = Color(0xFFD4AF37);

  /// ذهبي غامق - لنص/أيقونات على خلفيات فاتحة (تباين أوضح من [accent]).
  static const Color accentDark = Color(0xFF9C7A2A);
  static const Color accentLight = Color(0xFFFBF1D9);

  static const Color background = Color(0xFFFAF7F1);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1F2D2A);
  static const Color textSecondary = Color(0xFF6E7B76);
  static const Color textMuted = Color(0xFFA3ADA9);

  static const Color divider = Color(0xFFEDE7DA);

  static const Color streak = accentDark;
  static const Color abandoned = accentDark;
  static const Color success = Color(0xFF3F8F5C);
  static const Color error = Color(0xFFC0392B);
}

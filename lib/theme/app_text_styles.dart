import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// أنماط النصوص المستخدمة في التطبيق.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base =>
      GoogleFonts.tajawal(color: AppColors.textPrimary);

  static TextStyle get appTitle =>
      _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700);

  static TextStyle get screenTitle =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);

  static TextStyle get sectionTitle =>
      _base.copyWith(fontSize: 17, fontWeight: FontWeight.w700);

  static TextStyle get cardTitle =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  static TextStyle get body =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle get bodyBold => body.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get caption =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondary);

  static TextStyle get button =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700);

  /// نمط نص الحديث - خط عربي تقليدي مع تباعد سطور مريح للقراءة.
  static TextStyle get hadithText => GoogleFonts.notoNaskhArabic(
        color: AppColors.textPrimary,
        fontSize: 19,
        height: 1.9,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get badge =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w700);
}

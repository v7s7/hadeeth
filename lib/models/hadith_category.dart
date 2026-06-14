import 'package:flutter/material.dart';

/// تصنيف من تصنيفات الأحاديث (السنن المهجورة، الأخلاق، الصلاة...).
class HadithCategory {
  final String id;
  final String nameAr;
  final IconData icon;

  const HadithCategory({
    required this.id,
    required this.nameAr,
    required this.icon,
  });
}

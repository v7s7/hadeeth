import 'package:flutter/material.dart';

import '../data/category_icons.dart';

/// تصنيف من تصنيفات الأحاديث (السنن المهجورة، الأخلاق، الصلاة...).
class HadithCategory {
  final String id;
  final String nameAr;
  final String iconKey;
  final bool isHidden;

  const HadithCategory({
    required this.id,
    required this.nameAr,
    required this.iconKey,
    this.isHidden = false,
  });

  /// الأيقونة المقابلة لمفتاح الأيقونة المخزَّن.
  IconData get icon => categoryIcons[iconKey] ?? Icons.menu_book_outlined;

  HadithCategory copyWith({
    String? nameAr,
    String? iconKey,
    bool? isHidden,
  }) {
    return HadithCategory(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      iconKey: iconKey ?? this.iconKey,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'iconKey': iconKey,
      'isHidden': isHidden,
    };
  }

  factory HadithCategory.fromMap(String id, Map<String, dynamic> map) {
    return HadithCategory(
      id: id,
      nameAr: map['nameAr'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? 'menu_book_outlined',
      isHidden: map['isHidden'] as bool? ?? false,
    );
  }
}

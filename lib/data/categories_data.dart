import 'package:flutter/material.dart';

import '../models/hadith_category.dart';

const List<HadithCategory> hadithCategories = [
  HadithCategory(
    id: 'abandoned_sunnah',
    nameAr: 'السنن المهجورة',
    icon: Icons.auto_awesome_outlined,
  ),
  HadithCategory(
    id: 'manners',
    nameAr: 'الأخلاق',
    icon: Icons.favorite_outline,
  ),
  HadithCategory(
    id: 'prayer',
    nameAr: 'الصلاة',
    icon: Icons.mosque_outlined,
  ),
  HadithCategory(
    id: 'remembrance',
    nameAr: 'الذكر',
    icon: Icons.menu_book_outlined,
  ),
  HadithCategory(
    id: 'knowledge',
    nameAr: 'العلم',
    icon: Icons.school_outlined,
  ),
  HadithCategory(
    id: 'transactions',
    nameAr: 'المعاملات',
    icon: Icons.handshake_outlined,
  ),
  HadithCategory(
    id: 'sincerity',
    nameAr: 'النية والإخلاص',
    icon: Icons.spa_outlined,
  ),
  HadithCategory(
    id: 'daily_manners',
    nameAr: 'الآداب اليومية',
    icon: Icons.wb_sunny_outlined,
  ),
];

HadithCategory? categoryById(String id) {
  for (final category in hadithCategories) {
    if (category.id == id) return category;
  }
  return null;
}

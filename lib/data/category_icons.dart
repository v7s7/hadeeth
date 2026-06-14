import 'package:flutter/material.dart';

/// خريطة الأيقونات المتاحة لتصنيفات الأحاديث.
///
/// تُخزَّن مفاتيح هذه الخريطة فقط في قاعدة البيانات (Firestore) لأن
/// [IconData] لا يمكن تخزينه مباشرة، ثم تُستخدم لعرض الأيقونة المناسبة
/// ولإتاحة اختيار أيقونة من لوحة التحكم عند إضافة/تعديل تصنيف.
const Map<String, IconData> categoryIcons = {
  'auto_awesome_outlined': Icons.auto_awesome_outlined,
  'favorite_outline': Icons.favorite_outline,
  'mosque_outlined': Icons.mosque_outlined,
  'menu_book_outlined': Icons.menu_book_outlined,
  'school_outlined': Icons.school_outlined,
  'handshake_outlined': Icons.handshake_outlined,
  'spa_outlined': Icons.spa_outlined,
  'wb_sunny_outlined': Icons.wb_sunny_outlined,
  'people_outline': Icons.people_outline,
  'home_outlined': Icons.home_outlined,
  'star_outline': Icons.star_outline,
  'volunteer_activism_outlined': Icons.volunteer_activism_outlined,
  'eco_outlined': Icons.eco_outlined,
  'nightlight_outlined': Icons.nightlight_outlined,
  'family_restroom_outlined': Icons.family_restroom_outlined,
  'self_improvement_outlined': Icons.self_improvement_outlined,
  'emoji_events_outlined': Icons.emoji_events_outlined,
  'lightbulb_outline': Icons.lightbulb_outline,
  'groups_outlined': Icons.groups_outlined,
  'water_drop_outlined': Icons.water_drop_outlined,
  'park_outlined': Icons.park_outlined,
  'celebration_outlined': Icons.celebration_outlined,
  'favorite_border': Icons.favorite_border,
  'bookmark_outline': Icons.bookmark_outline,
};

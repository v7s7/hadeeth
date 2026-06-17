import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'user_progress.dart';

enum AccessoryCategory {
  misbah,
  umbrella,
  frame,
  badge,
  lantern,
  notebook;

  String get labelAr {
    switch (this) {
      case AccessoryCategory.misbah:
        return 'مسباح';
      case AccessoryCategory.umbrella:
        return 'مظلة';
      case AccessoryCategory.frame:
        return 'إطار';
      case AccessoryCategory.badge:
        return 'شارة';
      case AccessoryCategory.lantern:
        return 'فانوس';
      case AccessoryCategory.notebook:
        return 'دفتر';
    }
  }
}

class AppAccessory {
  final String id;
  final AccessoryCategory category;
  final String nameAr;
  final String descriptionAr;
  final String emoji;
  final String imagePath;
  final Color color;
  final int requiredXp;
  final int requiredStreak;

  const AppAccessory({
    required this.id,
    required this.category,
    required this.nameAr,
    required this.descriptionAr,
    required this.emoji,
    required this.imagePath,
    required this.color,
    this.requiredXp = 0,
    this.requiredStreak = 0,
  });

  bool isUnlocked(UserProgress progress) =>
      progress.totalXp >= requiredXp && progress.currentStreak >= requiredStreak;

  String unlockHint(UserProgress progress) {
    if (isUnlocked(progress)) return 'متاح الآن';
    if (requiredStreak > progress.currentStreak) {
      return 'يحتاج سلسلة $requiredStreak أيام';
    }
    return 'يحتاج $requiredXp XP';
  }
}

class AppAccessories {
  AppAccessories._();

  static const amberMisbah = AppAccessory(
    id: 'misbah_amber',
    category: AccessoryCategory.misbah,
    nameAr: 'مسباح كهرمان',
    descriptionAr: 'رفيق هادئ يلمع مع وردك اليومي.',
    emoji: '📿',
    imagePath: 'assets/images/accessories/misbah_amber.png',
    color: Color(0xFFD69A2D),
  );

  static const woodMisbah = AppAccessory(
    id: 'misbah_wood',
    category: AccessoryCategory.misbah,
    nameAr: 'مسباح خشبي',
    descriptionAr: 'بسيط ودافئ للمداومة اليومية.',
    emoji: '📿',
    imagePath: 'assets/images/accessories/misbah_wood.png',
    color: Color(0xFF8B5E3C),
    requiredXp: 100,
  );

  static const blackMisbah = AppAccessory(
    id: 'misbah_black',
    category: AccessoryCategory.misbah,
    nameAr: 'مسباح أسود',
    descriptionAr: 'هادئ وأنيق لأصحاب السلاسل الطويلة.',
    emoji: '📿',
    imagePath: 'assets/images/accessories/misbah_black.png',
    color: Color(0xFF20242A),
    requiredStreak: 7,
  );

  static const blueUmbrella = AppAccessory(
    id: 'umbrella_blue',
    category: AccessoryCategory.umbrella,
    nameAr: 'مظلة زرقاء',
    descriptionAr: 'لمسة لطيفة تناسب الغترة الزرقاء.',
    emoji: '☂️',
    imagePath: 'assets/images/accessories/umbrella_blue.png',
    color: Color(0xFF5D8CCB),
    requiredXp: 150,
  );

  static const goldUmbrella = AppAccessory(
    id: 'umbrella_gold',
    category: AccessoryCategory.umbrella,
    nameAr: 'مظلة ذهبية',
    descriptionAr: 'لمسة فاخرة تناسب البشت الذهبي.',
    emoji: '☂️',
    imagePath: 'assets/images/accessories/umbrella_gold.png',
    color: Color(0xFFD6AA4A),
    requiredXp: 200,
  );

  static const redUmbrella = AppAccessory(
    id: 'umbrella_red',
    category: AccessoryCategory.umbrella,
    nameAr: 'مظلة حمراء',
    descriptionAr: 'لمسة جريئة تناسب الشماغ الأحمر.',
    emoji: '☂️',
    imagePath: 'assets/images/accessories/umbrella_red.png',
    color: Color(0xFFBE3F35),
    requiredStreak: 10,
  );

  static const goldFrame = AppAccessory(
    id: 'frame_gold',
    category: AccessoryCategory.frame,
    nameAr: 'إطار ذهبي',
    descriptionAr: 'إطار نوراني يظهر حول رفيقك.',
    emoji: '🏵️',
    imagePath: 'assets/images/accessories/frame_gold.png',
    color: AppColors.accent,
    requiredStreak: 14,
  );

  static const knowledgeBadge = AppAccessory(
    id: 'badge_knowledge',
    category: AccessoryCategory.badge,
    nameAr: 'شارة طالب علم',
    descriptionAr: 'شارة صغيرة لمن يثبت على التعلم.',
    emoji: '🌟',
    imagePath: 'assets/images/accessories/badge_knowledge.png',
    color: Color(0xFF1F6F5C),
    requiredXp: 250,
  );

  static const goldLantern = AppAccessory(
    id: 'lantern_gold',
    category: AccessoryCategory.lantern,
    nameAr: 'فانوس ذهبي',
    descriptionAr: 'نور دائم لمن واصل رحلة العلم.',
    emoji: '🏮',
    imagePath: 'assets/images/accessories/lantern_gold.png',
    color: AppColors.accent,
    requiredXp: 350,
  );

  static const tealNotebook = AppAccessory(
    id: 'notebook_teal',
    category: AccessoryCategory.notebook,
    nameAr: 'دفتر الحديث',
    descriptionAr: 'دفتر أنيق لأصحاب السلاسل الطويلة جدًا.',
    emoji: '📗',
    imagePath: 'assets/images/accessories/notebook_teal.png',
    color: Color(0xFF36645B),
    requiredStreak: 21,
  );

  static const List<AppAccessory> all = [
    amberMisbah,
    woodMisbah,
    blackMisbah,
    blueUmbrella,
    goldUmbrella,
    redUmbrella,
    goldFrame,
    knowledgeBadge,
    goldLantern,
    tealNotebook,
  ];

  static AppAccessory defaultAccessory() => amberMisbah;

  static AppAccessory? findById(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((accessory) => accessory.id == id);
    } catch (_) {
      return null;
    }
  }
}

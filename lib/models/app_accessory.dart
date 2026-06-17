import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'user_progress.dart';

enum AccessoryCategory {
  misbah,
  umbrella,
  frame,
  badge;

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
    }
  }
}

class AppAccessory {
  final String id;
  final AccessoryCategory category;
  final String nameAr;
  final String descriptionAr;
  final String emoji;
  final Color color;
  final int requiredXp;
  final int requiredStreak;

  const AppAccessory({
    required this.id,
    required this.category,
    required this.nameAr,
    required this.descriptionAr,
    required this.emoji,
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
    color: Color(0xFFD69A2D),
  );

  static const woodMisbah = AppAccessory(
    id: 'misbah_wood',
    category: AccessoryCategory.misbah,
    nameAr: 'مسباح خشبي',
    descriptionAr: 'بسيط ودافئ للمداومة اليومية.',
    emoji: '📿',
    color: Color(0xFF8B5E3C),
    requiredXp: 100,
  );

  static const blackMisbah = AppAccessory(
    id: 'misbah_black',
    category: AccessoryCategory.misbah,
    nameAr: 'مسباح أسود',
    descriptionAr: 'هادئ وأنيق لأصحاب السلاسل الطويلة.',
    emoji: '📿',
    color: Color(0xFF20242A),
    requiredStreak: 7,
  );

  static const blueUmbrella = AppAccessory(
    id: 'umbrella_blue',
    category: AccessoryCategory.umbrella,
    nameAr: 'مظلة زرقاء',
    descriptionAr: 'لمسة لطيفة تناسب الغترة الزرقاء.',
    emoji: '☂️',
    color: Color(0xFF5D8CCB),
    requiredXp: 150,
  );

  static const goldFrame = AppAccessory(
    id: 'frame_gold',
    category: AccessoryCategory.frame,
    nameAr: 'إطار ذهبي',
    descriptionAr: 'إطار نوراني يظهر حول رفيقك.',
    emoji: '🏵️',
    color: AppColors.accent,
    requiredStreak: 14,
  );

  static const knowledgeBadge = AppAccessory(
    id: 'badge_knowledge',
    category: AccessoryCategory.badge,
    nameAr: 'شارة طالب علم',
    descriptionAr: 'شارة صغيرة لمن يثبت على التعلم.',
    emoji: '🌟',
    color: Color(0xFF1F6F5C),
    requiredXp: 250,
  );

  static const List<AppAccessory> all = [
    amberMisbah,
    woodMisbah,
    blackMisbah,
    blueUmbrella,
    goldFrame,
    knowledgeBadge,
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

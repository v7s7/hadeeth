import '../models/app_level.dart';

/// جدول المستويات حسب نظام النقاط (XP) في المواصفات.
const List<AppLevel> appLevels = [
  AppLevel(level: 1, titleAr: 'مبتدئ', xpRequired: 0),
  AppLevel(level: 2, titleAr: 'طالب حديث', xpRequired: 100),
  AppLevel(level: 3, titleAr: 'محب السنة', xpRequired: 250),
  AppLevel(level: 4, titleAr: 'حافظ الأثر', xpRequired: 500),
  AppLevel(level: 5, titleAr: 'رفيق السنة', xpRequired: 850),
  AppLevel(level: 6, titleAr: 'ناشر الخير', xpRequired: 1300),
  AppLevel(level: 7, titleAr: 'ثابت على الأثر', xpRequired: 1900),
  AppLevel(level: 8, titleAr: 'صاحب الهمة', xpRequired: 2700),
  AppLevel(level: 9, titleAr: 'متمكن', xpRequired: 3700),
  AppLevel(level: 10, titleAr: 'من أهل المداومة', xpRequired: 5000),
];

/// يعيد المستوى الحالي بناءً على إجمالي نقاط الخبرة.
AppLevel levelForXp(int totalXp) {
  AppLevel current = appLevels.first;
  for (final level in appLevels) {
    if (totalXp >= level.xpRequired) {
      current = level;
    } else {
      break;
    }
  }
  return current;
}

/// يعيد المستوى التالي، أو null إذا كان المستخدم في أعلى مستوى.
AppLevel? nextLevelForXp(int totalXp) {
  final current = levelForXp(totalXp);
  final currentIndex = appLevels.indexOf(current);
  if (currentIndex + 1 < appLevels.length) {
    return appLevels[currentIndex + 1];
  }
  return null;
}

/// نسبة التقدم بين المستوى الحالي والمستوى التالي (من 0 إلى 1).
double levelProgress(int totalXp) {
  final current = levelForXp(totalXp);
  final next = nextLevelForXp(totalXp);
  if (next == null) return 1;
  final span = next.xpRequired - current.xpRequired;
  if (span <= 0) return 1;
  final progress = (totalXp - current.xpRequired) / span;
  return progress.clamp(0, 1).toDouble();
}

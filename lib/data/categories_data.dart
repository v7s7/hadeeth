import '../models/hadith_category.dart';

/// التصنيفات الافتراضية (Seed data)، تُستخدم عند عدم توفر بيانات من Firestore.
const List<HadithCategory> hadithCategories = [
  HadithCategory(
    id: 'abandoned_sunnah',
    nameAr: 'السنن المهجورة',
    iconKey: 'auto_awesome_outlined',
  ),
  HadithCategory(
    id: 'manners',
    nameAr: 'الأخلاق',
    iconKey: 'favorite_outline',
  ),
  HadithCategory(
    id: 'prayer',
    nameAr: 'الصلاة',
    iconKey: 'mosque_outlined',
  ),
  HadithCategory(
    id: 'remembrance',
    nameAr: 'الذكر',
    iconKey: 'menu_book_outlined',
  ),
  HadithCategory(
    id: 'knowledge',
    nameAr: 'العلم',
    iconKey: 'school_outlined',
  ),
  HadithCategory(
    id: 'transactions',
    nameAr: 'المعاملات',
    iconKey: 'handshake_outlined',
  ),
  HadithCategory(
    id: 'sincerity',
    nameAr: 'النية والإخلاص',
    iconKey: 'spa_outlined',
  ),
  HadithCategory(
    id: 'daily_manners',
    nameAr: 'الآداب اليومية',
    iconKey: 'wb_sunny_outlined',
  ),
];

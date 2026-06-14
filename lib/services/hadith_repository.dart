import '../data/categories_data.dart';
import '../data/sample_hadiths.dart';
import '../models/enums.dart';
import '../models/hadith.dart';

/// طبقة الوصول إلى بيانات الأحاديث.
///
/// في هذه المرحلة تُستخدم بيانات تجريبية ثابتة (sampleHadiths)، وفي مرحلة
/// لاحقة يمكن استبدال هذا التنفيذ بمصدر بيانات من Firestore دون تغيير
/// الواجهة التي تستخدمها الشاشات.
class HadithRepository {
  List<Hadith> get all => sampleHadiths;

  List<Hadith> get published => sampleHadiths
      .where((hadith) => hadith.status == ContentStatus.published)
      .toList();

  Hadith? getById(String id) {
    for (final hadith in sampleHadiths) {
      if (hadith.id == id) return hadith;
    }
    return null;
  }

  /// حديث اليوم: يتغيّر يوميًا بشكل ثابت (لا يعتمد على عشوائية).
  Hadith hadithOfTheDay() {
    final items = published;
    final index = _dayOfYear(DateTime.now()) % items.length;
    return items[index];
  }

  /// الأحاديث/السنن المهجورة.
  List<Hadith> abandoned() =>
      published.where((hadith) => hadith.isAbandonedSunnah).toList();

  /// آخر ما أضيف من الأحاديث، الأحدث أولاً.
  List<Hadith> recentlyAdded({int limit = 10}) {
    final items = [...published]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  /// أحاديث تصنيف معيّن.
  List<Hadith> byCategory(String categoryId) =>
      published.where((hadith) => hadith.categoryId == categoryId).toList();

  /// بحث نصي يشمل نص الحديث، الراوي، المصدر، التصنيف والوسوم.
  List<Hadith> search(String query, {bool abandonedOnly = false}) {
    var items = published;
    if (abandonedOnly) {
      items = items.where((hadith) => hadith.isAbandonedSunnah).toList();
    }

    final normalized = query.trim();
    if (normalized.isEmpty) return items;

    return items.where((hadith) {
      final categoryName = categoryById(hadith.categoryId)?.nameAr ?? '';
      return hadith.hadithText.contains(normalized) ||
          hadith.title.contains(normalized) ||
          hadith.narrator.contains(normalized) ||
          hadith.sourceBook.contains(normalized) ||
          categoryName.contains(normalized) ||
          hadith.tags.any((tag) => tag.contains(normalized));
    }).toList();
  }

  int _dayOfYear(DateTime date) =>
      date.difference(DateTime(date.year, 1, 1)).inDays;
}

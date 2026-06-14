import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/sample_hadiths.dart';
import '../models/enums.dart';
import '../models/hadith.dart';
import 'category_repository.dart';

/// طبقة الوصول إلى بيانات الأحاديث.
///
/// تُهيَّأ القائمة مبدئيًا من بيانات تجريبية ثابتة (sampleHadiths) لضمان عمل
/// التطبيق فورًا دون أي إعداد، ثم تحاول الاشتراك في مجموعة `hadiths` على
/// Firestore. إذا توفرت مستندات هناك يتم استبدال القائمة المحلية بها تلقائيًا
/// وتُحدَّث الواجهات عبر [notifyListeners]. وإذا لم تكن Firebase مهيّأة أو
/// كانت المجموعة فارغة، تبقى البيانات التجريبية كما هي دون أي خطأ.
class HadithRepository extends ChangeNotifier {
  final CategoryRepository _categoryRepository;
  late List<Hadith> _hadiths;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  HadithRepository(this._categoryRepository) {
    _hadiths = List.of(sampleHadiths);
    _listenToFirestore();
  }

  void _listenToFirestore() {
    try {
      _subscription = FirebaseFirestore.instance.collection('hadiths').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) return;
          _hadiths = snapshot.docs.map((doc) => Hadith.fromMap(doc.id, doc.data())).toList();
          notifyListeners();
        },
        onError: (_) {},
      );
    } catch (_) {
      // Firebase غير مهيّأ؛ تبقى البيانات التجريبية المحلية كما هي.
    }
  }

  /// كل الأحاديث (تشمل المسودات والمخفية) - لاستخدام لوحة التحكم.
  List<Hadith> get all => _hadiths;

  List<Hadith> get published =>
      _hadiths.where((hadith) => hadith.status == ContentStatus.published).toList();

  Hadith? getById(String id) {
    for (final hadith in _hadiths) {
      if (hadith.id == id) return hadith;
    }
    return null;
  }

  /// حديث اليوم: يتغيّر يوميًا بشكل ثابت (لا يعتمد على عشوائية).
  Hadith hadithOfTheDay() {
    final items = published;
    if (items.isEmpty) {
      return _hadiths.isNotEmpty ? _hadiths.first : sampleHadiths.first;
    }
    final index = _dayOfYear(DateTime.now()) % items.length;
    return items[index];
  }

  /// الأحاديث/السنن المهجورة.
  List<Hadith> abandoned() => published.where((hadith) => hadith.isAbandonedSunnah).toList();

  /// آخر ما أضيف من الأحاديث، الأحدث أولاً.
  List<Hadith> recentlyAdded({int limit = 10}) {
    final items = [...published]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      final categoryName = _categoryRepository.categoryById(hadith.categoryId)?.nameAr ?? '';
      return hadith.hadithText.contains(normalized) ||
          hadith.title.contains(normalized) ||
          hadith.narrator.contains(normalized) ||
          hadith.sourceBook.contains(normalized) ||
          categoryName.contains(normalized) ||
          hadith.tags.any((tag) => tag.contains(normalized));
    }).toList();
  }

  /// إضافة حديث جديد. تتطلب إعداد Firebase (لوحة التحكم).
  Future<void> addHadith(Hadith hadith) async {
    await FirebaseFirestore.instance.collection('hadiths').add(hadith.toMap());
  }

  /// تعديل حديث موجود. تتطلب إعداد Firebase (لوحة التحكم).
  Future<void> updateHadith(Hadith hadith) async {
    await FirebaseFirestore.instance.collection('hadiths').doc(hadith.id).set(hadith.toMap());
  }

  /// حذف حديث. تتطلب إعداد Firebase (لوحة التحكم).
  Future<void> deleteHadith(String id) async {
    await FirebaseFirestore.instance.collection('hadiths').doc(id).delete();
  }

  /// تغيير حالة النشر (نشر/إخفاء/مسودة) من لوحة التحكم.
  Future<void> setStatus(String id, ContentStatus status) async {
    await FirebaseFirestore.instance.collection('hadiths').doc(id).update({
      'status': status.name,
    });
  }

  int _dayOfYear(DateTime date) => date.difference(DateTime(date.year, 1, 1)).inDays;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

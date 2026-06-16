import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/hadith.dart';
import 'category_repository.dart';

/// طبقة الوصول إلى بيانات الأحاديث — Firestore فقط، لا بيانات تجريبية.
///
/// [isLoaded] يصبح true بعد أول رد من Firestore (سواء فارغًا أو لا).
/// استخدم [isLoaded] في الواجهة لعرض شاشة تحميل حتى تصل البيانات.
class HadithRepository extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<Hadith> _hadiths = const [];
  bool _isLoaded = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  HadithRepository(this._categoryRepository) {
    _listenToFirestore();
  }

  /// هل وصل أول رد من Firestore؟
  bool get isLoaded => _isLoaded;

  void _listenToFirestore() {
    try {
      _subscription = FirebaseFirestore.instance
          .collection('hadiths')
          .snapshots()
          .listen(
        (snapshot) {
          _hadiths = snapshot.docs
              .map((doc) => Hadith.fromMap(doc.id, doc.data()))
              .toList();
          _isLoaded = true;
          notifyListeners();
        },
        onError: (_) {
          // خطأ في الشبكة — نعتبرها محمّلة بقائمة فارغة حتى لا تتجمّد الواجهة.
          _isLoaded = true;
          notifyListeners();
        },
      );
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// كل الأحاديث (تشمل المسودات والمخفية) — لاستخدام لوحة التحكم.
  List<Hadith> get all => _hadiths;

  /// الأحاديث المنشورة فقط.
  List<Hadith> get published =>
      _hadiths.where((h) => h.status == ContentStatus.published).toList();

  Hadith? getById(String id) {
    for (final h in _hadiths) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// حديث اليوم. يعيد null إذا لم تتوفر أحاديث منشورة بعد.
  Hadith? hadithOfTheDay() {
    final items = published;
    if (items.isEmpty) return null;
    final index = _dayOfYear(DateTime.now()) % items.length;
    return items[index];
  }

  /// الأحاديث/السنن المهجورة.
  List<Hadith> abandoned() =>
      published.where((h) => h.isAbandonedSunnah).toList();

  /// آخر ما أضيف من الأحاديث، الأحدث أولاً.
  List<Hadith> recentlyAdded({int limit = 10}) {
    final items = [...published]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  /// أحاديث تصنيف معيّن.
  List<Hadith> byCategory(String categoryId) =>
      published.where((h) => h.categoryId == categoryId).toList();

  /// بحث نصي يشمل نص الحديث، الراوي، المصدر، التصنيف والوسوم.
  List<Hadith> search(String query, {bool abandonedOnly = false}) {
    var items = published;
    if (abandonedOnly) {
      items = items.where((h) => h.isAbandonedSunnah).toList();
    }
    final q = query.trim();
    if (q.isEmpty) return items;

    return items.where((h) {
      final catName =
          _categoryRepository.categoryById(h.categoryId)?.nameAr ?? '';
      return h.hadithText.contains(q) ||
          h.title.contains(q) ||
          h.narrator.contains(q) ||
          h.sourceBook.contains(q) ||
          catName.contains(q) ||
          h.tags.any((t) => t.contains(q));
    }).toList();
  }

  Future<void> addHadith(Hadith hadith) async {
    await FirebaseFirestore.instance
        .collection('hadiths')
        .add(hadith.toMap());
  }

  Future<void> updateHadith(Hadith hadith) async {
    await FirebaseFirestore.instance
        .collection('hadiths')
        .doc(hadith.id)
        .set(hadith.toMap());
  }

  Future<void> deleteHadith(String id) async {
    await FirebaseFirestore.instance.collection('hadiths').doc(id).delete();
  }

  Future<void> setStatus(String id, ContentStatus status) async {
    await FirebaseFirestore.instance
        .collection('hadiths')
        .doc(id)
        .update({'status': status.name});
  }

  int _dayOfYear(DateTime date) =>
      date.difference(DateTime(date.year, 1, 1)).inDays;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

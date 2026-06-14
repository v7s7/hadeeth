import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/categories_data.dart';
import '../models/hadith_category.dart';

/// طبقة الوصول إلى بيانات التصنيفات.
///
/// تُهيَّأ القائمة مبدئيًا من بيانات تجريبية ثابتة (hadithCategories) لضمان
/// عمل التطبيق فورًا دون أي إعداد، ثم تحاول الاشتراك في مجموعة `categories`
/// على Firestore. إذا توفرت مستندات هناك يتم استبدال القائمة المحلية بها
/// تلقائيًا، وإن لم تكن Firebase مهيّأة تبقى البيانات المحلية كما هي.
class CategoryRepository extends ChangeNotifier {
  late List<HadithCategory> _categories;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  CategoryRepository() {
    _categories = List.of(hadithCategories);
    _listenToFirestore();
  }

  void _listenToFirestore() {
    try {
      _subscription = FirebaseFirestore.instance.collection('categories').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) return;
          _categories =
              snapshot.docs.map((doc) => HadithCategory.fromMap(doc.id, doc.data())).toList();
          notifyListeners();
        },
        onError: (_) {},
      );
    } catch (_) {
      // Firebase غير مهيّأ؛ تبقى البيانات المحلية كما هي.
    }
  }

  /// كل التصنيفات (تشمل المخفية) - لاستخدام لوحة التحكم.
  List<HadithCategory> get categories => _categories;

  /// التصنيفات الظاهرة للمستخدمين فقط.
  List<HadithCategory> get visibleCategories =>
      _categories.where((category) => !category.isHidden).toList();

  HadithCategory? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// إضافة تصنيف جديد. تتطلب إعداد Firebase (لوحة التحكم).
  Future<void> addCategory(HadithCategory category) async {
    await FirebaseFirestore.instance.collection('categories').add(category.toMap());
  }

  /// تعديل تصنيف موجود. تتطلب إعداد Firebase (لوحة التحكم).
  Future<void> updateCategory(HadithCategory category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(category.id)
        .set(category.toMap());
  }

  /// حذف تصنيف. تتطلب إعداد Firebase (لوحة التحكم).
  Future<void> deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  }

  /// إخفاء/إظهار تصنيف للمستخدمين من لوحة التحكم.
  Future<void> setHidden(String id, bool isHidden) async {
    await FirebaseFirestore.instance.collection('categories').doc(id).update({
      'isHidden': isHidden,
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

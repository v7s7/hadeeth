import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/hadith_category.dart';

/// طبقة الوصول إلى بيانات التصنيفات — Firestore فقط، لا بيانات تجريبية.
///
/// [isLoaded] يصبح true بعد أول رد من Firestore.
class CategoryRepository extends ChangeNotifier {
  List<HadithCategory> _categories = const [];
  bool _isLoaded = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  CategoryRepository() {
    _listenToFirestore();
  }

  /// هل وصل أول رد من Firestore؟
  bool get isLoaded => _isLoaded;

  void _listenToFirestore() {
    try {
      _subscription = FirebaseFirestore.instance
          .collection('categories')
          .snapshots()
          .listen(
        (snapshot) {
          _categories = snapshot.docs
              .map((doc) => HadithCategory.fromMap(doc.id, doc.data()))
              .toList();
          _isLoaded = true;
          notifyListeners();
        },
        onError: (_) {
          _isLoaded = true;
          notifyListeners();
        },
      );
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// كل التصنيفات — لاستخدام لوحة التحكم.
  List<HadithCategory> get categories => _categories;

  /// التصنيفات الظاهرة للمستخدمين فقط.
  List<HadithCategory> get visibleCategories =>
      _categories.where((c) => !c.isHidden).toList();

  HadithCategory? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> addCategory(HadithCategory category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .add(category.toMap());
  }

  Future<void> updateCategory(HadithCategory category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(category.id)
        .set(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  }

  Future<void> setHidden(String id, bool isHidden) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(id)
        .update({'isHidden': isHidden});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

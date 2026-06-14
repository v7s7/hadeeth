import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_progress.dart';

/// تخزين تقدّم المستخدم محليًا على الجهاز (وضع الضيف).
///
/// لاحقًا، يمكن إضافة مزامنة هذه البيانات مع Firestore للمستخدمين
/// المسجّلين بدون تغيير الواجهة العامة لهذه الخدمة.
class LocalStorageService {
  static const String _progressKey = 'user_progress_v1';

  Future<UserProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null) return UserProgress.initial();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProgress.fromJson(json);
    } catch (_) {
      return UserProgress.initial();
    }
  }

  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }
}

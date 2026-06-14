import 'package:flutter/foundation.dart';

/// يمثل حالة جلسة المستخدم (ضيف أو مسجّل).
///
/// هذه نسخة مبدئية بدون مصادقة حقيقية، تُستخدم لعرض حالتي الضيف والمستخدم
/// المسجّل في الواجهات. لاحقًا تُستبدل بـ Firebase Auth (دخول Apple/Google)
/// دون تغيير الواجهة التي تستخدمها الشاشات.
class SessionService extends ChangeNotifier {
  bool _isGuest = true;
  String? _displayName;

  bool get isGuest => _isGuest;
  String? get displayName => _displayName;

  void completeSignIn(String name) {
    _isGuest = false;
    _displayName = name;
    notifyListeners();
  }

  void signOut() {
    _isGuest = true;
    _displayName = null;
    notifyListeners();
  }
}

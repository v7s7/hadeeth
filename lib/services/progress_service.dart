import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/levels_data.dart';
import '../models/app_level.dart';
import '../models/user_progress.dart';
import 'local_storage_service.dart';

/// يحتفظ بتقدّم المستخدم ويطبّق قواعد نظام النقاط (XP) والمستويات والسلسلة
/// اليومية (Streak) كما هي محددة في مواصفات المشروع.
///
/// التخزين:
/// - دائمًا: SharedPreferences (يعمل بدون إنترنت وبدون حساب).
/// - عند تسجيل الدخول: يُدمج التقدّم المحلي مع Firestore (`users/{uid}/progress/data`)
///   ثم يُزامن كل تغيير مع السحابة تلقائيًا.
class ProgressService extends ChangeNotifier {
  ProgressService(this._storage) {
    _listenToAuth();
  }

  // قيم نظام النقاط من المواصفات.
  static const int baseDailyXpCap = 40;
  static const int xpReadHadith = 5;
  static const int xpMarkLearned = 5;
  static const int xpCompleteQuiz = 10;
  static const int xpPerfectQuizBonus = 5;
  static const int xpReviewHadith = 3;
  static const int xpDailyStreak = 5;

  /// تكلفة شراء تجميد السلسلة بالنقاط.
  static const int streakFreezeXpCost = 50;

  final LocalStorageService _storage;
  UserProgress _progress = UserProgress.initial();
  bool _isLoaded = false;
  String? _currentUid;
  StreamSubscription<User?>? _authSub;

  UserProgress get progress => _progress;
  bool get isLoaded => _isLoaded;

  AppLevel get currentLevel => levelForXp(_progress.totalXp);
  AppLevel? get nextLevel => nextLevelForXp(_progress.totalXp);
  double get levelProgressValue => levelProgress(_progress.totalXp);

  /// رصيد تجميد السلسلة الحالي.
  int get streakFreezeCount => _progress.streakFreezeCount;

  // ────────────────────────── Streak Multiplier ──────────────────────────

  /// مضاعف XP بناءً على طول السلسلة الحالية:
  ///   0–2 أيام: ×1.0  (بدون مكافأة)
  ///   3–6 أيام: ×1.2  (+20%)
  ///  7–13 أيام: ×1.5  (+50%) 🔥
  /// 14–29 أيام: ×1.75 (+75%) 🔥🔥
  /// 30+ يومًا : ×2.0  (مضاعفة!) 🔥🔥🔥
  double get streakMultiplier {
    final s = _progress.currentStreak;
    if (s >= 30) return 2.0;
    if (s >= 14) return 1.75;
    if (s >= 7)  return 1.5;
    if (s >= 3)  return 1.2;
    return 1.0;
  }

  /// نص المضاعف للعرض: "×1.5" أو "" إذا لم تكن هناك مكافأة.
  String get streakMultiplierLabel {
    final m = streakMultiplier;
    if (m == 1.0) return '';
    final s = m == m.roundToDouble() ? m.toInt().toString() : m.toString();
    return '×$s';
  }

  /// الحد الأقصى لـ XP اليومي — يرتفع مع السلسلة:
  ///   0-6   أيام: 40 XP
  ///   7-13  أيام: 55 XP
  ///   14-29 أيام: 70 XP
  ///   30+   أيام: 90 XP
  int get _effectiveDailyXpCap {
    final s = _progress.currentStreak;
    if (s >= 30) return 90;
    if (s >= 14) return 70;
    if (s >= 7)  return 55;
    return baseDailyXpCap;
  }

  // ────────────────────────── Auth listener ──────────────────────────

  void _listenToAuth() {
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) {
          if (_currentUid != null) {
            _currentUid = null;
            _progress = await _storage.loadProgress();
            _isLoaded = true;
            notifyListeners();
          }
        } else if (user.uid != _currentUid) {
          _currentUid = user.uid;
          await _mergeWithCloud(user.uid);
        }
      }, onError: (_) {});
    } catch (_) {
      // Firebase غير مهيّأ؛ يستمر التطبيق بالتخزين المحلي.
    }
  }

  Future<void> load() async {
    _progress = await _storage.loadProgress();
    _isLoaded = true;
    notifyListeners();
  }

  // ────────────────────────── Firestore sync ──────────────────────────

  Future<void> _mergeWithCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('data')
          .get();

      if (doc.exists && doc.data() != null) {
        final cloud = UserProgress.fromJson(doc.data()!);
        _progress = _progress.merge(cloud);
      }
    } catch (_) {
      // تعذّر الوصول إلى Firestore؛ نكمل بالبيانات المحلية.
    }

    _isLoaded = true;
    notifyListeners();
    await _persist();
  }

  // ────────────────────────── Public API ──────────────────────────

  bool isFavorite(String hadithId) =>
      _progress.savedHadithIds.contains(hadithId);

  bool isLearned(String hadithId) =>
      _progress.learnedHadithIds.contains(hadithId);

  bool isRead(String hadithId) => _progress.readHadithIds.contains(hadithId);

  /// عدد الأحاديث المقروءة اليوم.
  int get dailyHadithReadCount {
    final today = _dateKey(DateTime.now());
    // نعدّها من dailyActivityXp — إن كان فيه نشاط اليوم فالمستخدم قرأ شيئًا.
    // للحصول على العدد الدقيق نحتاج تتبّعًا مستقلاً؛ نُقدّره بقيم XP اليوم.
    // القيمة 5 XP = حديث واحد (xpReadHadith).
    final todayXp = _progress.dailyActivityXp[today] ?? 0;
    return (todayXp / xpReadHadith).floor().clamp(0, 99);
  }

  Future<void> toggleFavorite(String hadithId) async {
    final saved = Set<String>.from(_progress.savedHadithIds);
    if (!saved.remove(hadithId)) {
      saved.add(hadithId);
    }
    _progress = _progress.copyWith(savedHadithIds: saved);
    await _persist();
  }

  Future<int> recordHadithRead(String hadithId,
      {bool isHadithOfTheDay = false}) async {
    var xpGained = 0;

    if (!_progress.readHadithIds.contains(hadithId)) {
      final read = Set<String>.from(_progress.readHadithIds)..add(hadithId);
      _progress = _progress.copyWith(readHadithIds: read);
      xpGained += _addXp(xpReadHadith);
    }

    if (isHadithOfTheDay) {
      xpGained += _registerStreakActivity();
    }

    await _persist();
    return xpGained;
  }

  Future<int> markHadithLearned(String hadithId) async {
    if (_progress.learnedHadithIds.contains(hadithId)) return 0;

    final learned = Set<String>.from(_progress.learnedHadithIds)
      ..add(hadithId);
    _progress = _progress.copyWith(learnedHadithIds: learned);

    var xpGained = _addXp(xpMarkLearned);
    xpGained += _registerStreakActivity();

    await _persist();
    return xpGained;
  }

  Future<int> reviewHadith(String hadithId) async {
    final xpGained = _addXp(xpReviewHadith);
    await _persist();
    return xpGained;
  }

  Future<int> completeQuiz({required int correct, required int total}) async {
    var xpGained = _addXp(xpCompleteQuiz);
    if (total > 0 && correct == total) {
      xpGained += _addXp(xpPerfectQuizBonus);
    }

    _progress = _progress.copyWith(
      quizzesCompleted: _progress.quizzesCompleted + 1,
      quizCorrectAnswers: _progress.quizCorrectAnswers + correct,
      quizTotalAnswers: _progress.quizTotalAnswers + total,
    );

    xpGained += _registerStreakActivity();

    await _persist();
    return xpGained;
  }

  // ────────────────────────── Streak Freeze ──────────────────────────

  /// يشتري تجميد سلسلة واحد مقابل [streakFreezeXpCost] نقطة.
  /// يُعيد true إذا نجحت العملية، false إذا كانت النقاط غير كافية.
  Future<bool> buyStreakFreeze() async {
    if (_progress.totalXp < streakFreezeXpCost) return false;

    _progress = _progress.copyWith(
      totalXp: _progress.totalXp - streakFreezeXpCost,
      streakFreezeCount: _progress.streakFreezeCount + 1,
    );
    await _persist();
    return true;
  }

  // ────────────────────────── Stats helpers ──────────────────────────

  List<int> last7DaysXp() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _progress.dailyActivityXp[_dateKey(day)] ?? 0;
    });
  }

  // ────────────────────────── Private helpers ──────────────────────────

  Future<void> _persist() async {
    await _storage.saveProgress(_progress);

    if (_currentUid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .collection('progress')
            .doc('data')
            .set(_progress.toJson());
      } catch (_) {
        // الحفظ المحلي نجح؛ سيُعاد المحاولة عند أول اتصال.
      }
    }

    notifyListeners();
  }

  int _addXp(int amount) {
    if (amount <= 0) return 0;

    // طبّق مضاعف السلسلة على المبلغ الأصلي.
    final boosted = (amount * streakMultiplier).round();

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastXpKey =
        _progress.lastXpDate == null ? null : _dateKey(_progress.lastXpDate!);

    var dailyEarned = _progress.dailyXpEarned;
    if (lastXpKey != todayKey) {
      dailyEarned = 0;
    }

    final cap = _effectiveDailyXpCap;
    final remainingCap = cap - dailyEarned;
    if (remainingCap <= 0) {
      _progress = _progress.copyWith(dailyXpEarned: dailyEarned, lastXpDate: now);
      return 0;
    }

    final granted = boosted < remainingCap ? boosted : remainingCap;

    final activity = Map<String, int>.from(_progress.dailyActivityXp);
    activity[todayKey] = (activity[todayKey] ?? 0) + granted;

    _progress = _progress.copyWith(
      totalXp: _progress.totalXp + granted,
      dailyXpEarned: dailyEarned + granted,
      lastXpDate: now,
      dailyActivityXp: activity,
    );

    return granted;
  }

  int _registerStreakActivity() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastKey = _progress.lastActivityDate == null
        ? null
        : _dateKey(_progress.lastActivityDate!);

    // نشاط اليوم مسجّل بالفعل — لا داعي لتكراره.
    if (lastKey == todayKey) return 0;

    int newStreak;
    if (lastKey != null) {
      final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

      if (lastKey == yesterdayKey) {
        // المستخدم نشط أمس — السلسلة تستمر.
        newStreak = _progress.currentStreak + 1;
      } else {
        // المستخدم فاتته يوم على الأقل — هل يملك تجميد سلسلة؟
        final twoDaysAgoKey = _dateKey(now.subtract(const Duration(days: 2)));
        if (lastKey == twoDaysAgoKey && _progress.streakFreezeCount > 0) {
          // تجميد يُنقذ السلسلة من انقطاع يوم واحد فقط.
          _progress = _progress.copyWith(
            streakFreezeCount: _progress.streakFreezeCount - 1,
          );
          newStreak = _progress.currentStreak + 1;
        } else {
          // السلسلة تنكسر.
          newStreak = 1;
        }
      }
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > _progress.longestStreak ? newStreak : _progress.longestStreak;

    _progress = _progress.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActivityDate: now,
    );

    return _addXp(xpDailyStreak);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../data/levels_data.dart';
import '../models/app_level.dart';
import '../models/user_progress.dart';
import 'local_storage_service.dart';

/// يحتفظ بتقدّم المستخدم ويطبّق قواعد نظام النقاط (XP) والمستويات والسلسلة
/// اليومية (Streak) كما هي محددة في مواصفات المشروع.
class ProgressService extends ChangeNotifier {
  ProgressService(this._storage);

  // قيم نظام النقاط من المواصفات.
  static const int dailyXpCap = 40;
  static const int xpReadHadith = 5;
  static const int xpMarkLearned = 5;
  static const int xpCompleteQuiz = 10;
  static const int xpPerfectQuizBonus = 5;
  static const int xpReviewHadith = 3;
  static const int xpDailyStreak = 5;

  final LocalStorageService _storage;
  UserProgress _progress = UserProgress.initial();
  bool _isLoaded = false;

  UserProgress get progress => _progress;
  bool get isLoaded => _isLoaded;

  AppLevel get currentLevel => levelForXp(_progress.totalXp);
  AppLevel? get nextLevel => nextLevelForXp(_progress.totalXp);
  double get levelProgressValue => levelProgress(_progress.totalXp);

  Future<void> load() async {
    _progress = await _storage.loadProgress();
    _isLoaded = true;
    notifyListeners();
  }

  bool isFavorite(String hadithId) =>
      _progress.savedHadithIds.contains(hadithId);

  bool isLearned(String hadithId) =>
      _progress.learnedHadithIds.contains(hadithId);

  bool isRead(String hadithId) => _progress.readHadithIds.contains(hadithId);

  Future<void> toggleFavorite(String hadithId) async {
    final saved = Set<String>.from(_progress.savedHadithIds);
    if (!saved.remove(hadithId)) {
      saved.add(hadithId);
    }
    _progress = _progress.copyWith(savedHadithIds: saved);
    await _persist();
  }

  /// تسجيل قراءة حديث. يمنح نقاطًا فقط في أول قراءة، ويحسب يوم السلسلة
  /// إذا كان هذا الحديث هو "حديث اليوم".
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

  /// وضع علامة "تعلمت هذا الحديث". يمنح نقاطًا مرة واحدة فقط لكل حديث.
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

  /// مراجعة حديث تم تعلمه سابقًا.
  Future<int> reviewHadith(String hadithId) async {
    final xpGained = _addXp(xpReviewHadith);
    await _persist();
    return xpGained;
  }

  /// إكمال اختبار حديث، مع منح مكافأة إضافية للنتيجة الكاملة.
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

  /// نقاط الخبرة المكتسبة في كل يوم من آخر 7 أيام (الأقدم أولاً).
  List<int> last7DaysXp() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _progress.dailyActivityXp[_dateKey(day)] ?? 0;
    });
  }

  /// يضيف نقاطًا مع احترام الحد اليومي (40 نقطة)، ويعيد عدد النقاط
  /// المضافة فعليًا بعد الأخذ بالحد الأقصى بعين الاعتبار.
  int _addXp(int amount) {
    if (amount <= 0) return 0;

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastXpKey =
        _progress.lastXpDate == null ? null : _dateKey(_progress.lastXpDate!);

    var dailyEarned = _progress.dailyXpEarned;
    if (lastXpKey != todayKey) {
      dailyEarned = 0;
    }

    final remainingCap = dailyXpCap - dailyEarned;
    if (remainingCap <= 0) {
      _progress = _progress.copyWith(dailyXpEarned: dailyEarned, lastXpDate: now);
      return 0;
    }

    final granted = amount < remainingCap ? amount : remainingCap;

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

  /// يحدّث السلسلة اليومية عند أول نشاط مؤهل في اليوم، ويمنح مكافأة +5 XP.
  int _registerStreakActivity() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastKey = _progress.lastActivityDate == null
        ? null
        : _dateKey(_progress.lastActivityDate!);

    if (lastKey == todayKey) return 0;

    int newStreak;
    if (lastKey != null) {
      final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
      newStreak = lastKey == yesterdayKey ? _progress.currentStreak + 1 : 1;
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

  Future<void> _persist() async {
    await _storage.saveProgress(_progress);
    notifyListeners();
  }
}

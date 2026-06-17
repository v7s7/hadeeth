import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

import '../models/user_gender.dart';
import '../models/user_progress.dart';

/// تخزين تقدّم المستخدم وإعدادات التطبيق محليًا على الجهاز.
///
/// يحتفظ بذاكرة تخزين مؤقتة ثابتة (static) لأكثر القيم طلبًا (الجنس وحالة
/// الترحيب وحجم الخط والهدف اليومي) حتى تكون القراءة التالية فورية من الذاكرة.
class LocalStorageService {
  static const String _progressKey = 'user_progress_v1';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _welcomeKey = 'welcome_complete';
  static const String _genderKey = 'user_gender';
  static const String _notifEnabledKey = 'notifications_enabled';
  static const String _notifHourKey = 'notifications_hour';
  static const String _notifMinuteKey = 'notifications_minute';
  static const String _notifToneKey = 'notifications_tone';
  static const String _fontScaleKey = 'font_scale';
  static const String _dailyGoalKey = 'daily_goal';
  static const String _characterKey = 'character_id';
  static const String _activeAccessoryKey = 'active_accessory_id';
  static const String _preferredNameKey = 'preferred_name';

  // ذاكرة مؤقتة ثابتة — مشتركة بين جميع نسخ LocalStorageService.
  static UserGender? _genderCache;
  static bool? _welcomeCache;
  static double? _fontScaleCache;
  static int? _dailyGoalCache;
  static String? _characterCache;
  static String? _activeAccessoryCache;
  static String? _preferredNameCache;
  static NotificationTone? _notificationToneCache;

  /// الجنس المُخزَّن مؤقتًا — null إن لم يُحمَّل بعد.
  static UserGender? get cachedGender => _genderCache;

  /// هل اكتمل الترحيب — null يعني لم يُحمَّل بعد.
  static bool? get cachedWelcome => _welcomeCache;

  /// حجم الخط المُخزَّن مؤقتًا — null إن لم يُحمَّل بعد.
  static double? get cachedFontScale => _fontScaleCache;

  /// الهدف اليومي المُخزَّن مؤقتًا — null إن لم يُحمَّل بعد.
  static int? get cachedDailyGoal => _dailyGoalCache;

  /// معرّف الشخصية المُخزَّن مؤقتًا — null إن لم يُحمَّل بعد.
  static String? get cachedCharacterId => _characterCache;

  /// معرّف الرفيق/الإضافة النشطة للشخصية.
  static String? get cachedActiveAccessoryId => _activeAccessoryCache;

  /// الاسم الشخصي المحلي المستخدم للضيوف أو تخصيص الترحيب.
  static String? get cachedPreferredName => _preferredNameCache;

  /// نغمة التذكير اليومي المخزنة مؤقتًا.
  static NotificationTone? get cachedNotificationTone => _notificationToneCache;

  /// يُسخِّن الذاكرة المؤقتة مسبقًا — يُستدعى في شاشة البداية أثناء عرض الشعار.
  Future<void> preload() async {
    final prefs = await SharedPreferences.getInstance();
    _welcomeCache = prefs.getBool(_welcomeKey) ?? false;
    final raw = prefs.getString(_genderKey);
    if (raw != null) _genderCache = UserGender.fromString(raw);
    _fontScaleCache = prefs.getDouble(_fontScaleKey) ?? 1.0;
    _dailyGoalCache = prefs.getInt(_dailyGoalKey) ?? 3;
    _characterCache = prefs.getString(_characterKey);
    _activeAccessoryCache = prefs.getString(_activeAccessoryKey);
    _preferredNameCache = prefs.getString(_preferredNameKey);
    _notificationToneCache =
        NotificationTone.fromName(prefs.getString(_notifToneKey));
  }

  // ────────────────────────── Progress ──────────────────────────

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

  // ────────────────────────── Onboarding ──────────────────────────

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // ────────────────────────── Welcome / Gender ──────────────────────────

  /// هل أكمل المستخدم شاشة الترحيب (اختيار الجنس والشخصية).
  Future<bool> hasCompletedWelcome() async {
    if (_welcomeCache != null) return _welcomeCache!;
    final prefs = await SharedPreferences.getInstance();
    _welcomeCache = prefs.getBool(_welcomeKey) ?? false;
    return _welcomeCache!;
  }

  Future<void> markWelcomeComplete() async {
    _welcomeCache = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
    await prefs.setBool(_onboardingKey, true);
  }

  Future<UserGender?> loadGender() async {
    if (_genderCache != null) return _genderCache;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_genderKey);
    if (raw == null) return null;
    _genderCache = UserGender.fromString(raw);
    return _genderCache;
  }

  Future<void> saveGender(UserGender gender) async {
    _genderCache = gender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender.name);
  }

  // ────────────────────────── Font Scale ──────────────────────────

  /// يُعيد مقياس حجم الخط المحفوظ (1.0 / 1.3 / 1.6).
  Future<double> getFontScale() async {
    if (_fontScaleCache != null) return _fontScaleCache!;
    final prefs = await SharedPreferences.getInstance();
    _fontScaleCache = prefs.getDouble(_fontScaleKey) ?? 1.0;
    return _fontScaleCache!;
  }

  Future<void> setFontScale(double scale) async {
    _fontScaleCache = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
  }

  // ────────────────────────── Daily Goal ──────────────────────────

  /// يُعيد الهدف اليومي لعدد الأحاديث المقروءة (افتراضي: 3).
  Future<int> getDailyGoal() async {
    if (_dailyGoalCache != null) return _dailyGoalCache!;
    final prefs = await SharedPreferences.getInstance();
    _dailyGoalCache = prefs.getInt(_dailyGoalKey) ?? 3;
    return _dailyGoalCache!;
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoalCache = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, goal);
  }

  // ────────────────────────── Character ──────────────────────────

  Future<String?> loadCharacterId() async {
    if (_characterCache != null) return _characterCache;
    final prefs = await SharedPreferences.getInstance();
    _characterCache = prefs.getString(_characterKey);
    _activeAccessoryCache = prefs.getString(_activeAccessoryKey);
    _preferredNameCache = prefs.getString(_preferredNameKey);
    _notificationToneCache =
        NotificationTone.fromName(prefs.getString(_notifToneKey));
    return _characterCache;
  }

  Future<void> saveCharacterId(String id) async {
    _characterCache = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_characterKey, id);
  }

  Future<String?> loadActiveAccessoryId() async {
    if (_activeAccessoryCache != null) return _activeAccessoryCache;
    final prefs = await SharedPreferences.getInstance();
    _activeAccessoryCache = prefs.getString(_activeAccessoryKey);
    return _activeAccessoryCache;
  }

  Future<void> saveActiveAccessoryId(String id) async {
    _activeAccessoryCache = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccessoryKey, id);
  }

  // ────────────────────────── Preferred Name ──────────────────────────

  Future<String?> loadPreferredName() async {
    if (_preferredNameCache != null) return _preferredNameCache;
    final prefs = await SharedPreferences.getInstance();
    _preferredNameCache = prefs.getString(_preferredNameKey);
    _notificationToneCache =
        NotificationTone.fromName(prefs.getString(_notifToneKey));
    return _preferredNameCache;
  }

  Future<void> savePreferredName(String name) async {
    final trimmed = name.trim();
    _preferredNameCache = trimmed.isEmpty ? null : trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_preferredNameKey);
    } else {
      await prefs.setString(_preferredNameKey, trimmed);
    }
  }

  // ────────────────────────── Notifications ──────────────────────────

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEnabledKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, enabled);
  }

  Future<int> getNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifHourKey) ?? 8;
  }

  Future<int> getNotificationMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifMinuteKey) ?? 0;
  }

  Future<void> saveNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notifHourKey, hour);
    await prefs.setInt(_notifMinuteKey, minute);
  }

  Future<NotificationTone> getNotificationTone() async {
    if (_notificationToneCache != null) return _notificationToneCache!;
    final prefs = await SharedPreferences.getInstance();
    _notificationToneCache =
        NotificationTone.fromName(prefs.getString(_notifToneKey));
    return _notificationToneCache!;
  }

  Future<void> saveNotificationTone(NotificationTone tone) async {
    _notificationToneCache = tone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notifToneKey, tone.name);
  }
}

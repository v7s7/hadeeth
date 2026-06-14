import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_progress.dart';

/// تخزين تقدّم المستخدم وإعدادات التطبيق محليًا على الجهاز.
class LocalStorageService {
  static const String _progressKey = 'user_progress_v1';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _notifEnabledKey = 'notifications_enabled';
  static const String _notifHourKey = 'notifications_hour';
  static const String _notifMinuteKey = 'notifications_minute';

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

  // ────────────────────────── Notifications ──────────────────────────

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEnabledKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, enabled);
  }

  /// يُعيد ساعة التذكير المحفوظة (افتراضي 8 صباحًا).
  Future<int> getNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifHourKey) ?? 8;
  }

  /// يُعيد دقيقة التذكير المحفوظة (افتراضي 0).
  Future<int> getNotificationMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifMinuteKey) ?? 0;
  }

  Future<void> saveNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notifHourKey, hour);
    await prefs.setInt(_notifMinuteKey, minute);
  }
}

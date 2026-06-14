import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// يتيح جدولة تذكير يومي بحديث اليوم عبر إشعارات محلية.
///
/// استخدام:
/// 1. استدعِ [NotificationService.init] عند بدء تشغيل التطبيق.
/// 2. استدعِ [NotificationService.requestPermission] عند أول استخدام.
/// 3. استدعِ [scheduleDailyReminder] لتفعيل التذكير اليومي.
/// 4. استدعِ [cancelReminder] لإلغاء التذكير.
class NotificationService {
  NotificationService._();

  static const int _dailyReminderId = 0;
  static const String _channelId = 'daily_hadith_reminder';
  static const String _channelName = 'تذكير الحديث اليومي';
  static const String _channelDescription =
      'إشعار يومي يذكّرك بقراءة حديث اليوم';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// يُهيَّأ مرة واحدة في [main] قبل تشغيل التطبيق.
  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// يطلب إذن الإشعارات من المستخدم (iOS فقط، Android 13+ يحتاج إذنًا أيضًا).
  /// يُعيد true إذا منح المستخدم الإذن.
  static Future<bool> requestPermission() async {
    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  /// يجدول إشعارًا يوميًا يتكرر في [time] كل يوم.
  /// يُلغي أي جدولة سابقة أولاً.
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // إذا مرّ وقت الإشعار اليوم، ابدأ من الغد.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'الحديث المهجور',
      'حان وقت قراءة حديث اليوم 📖',
      scheduled,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// يُلغي التذكير اليومي.
  static Future<void> cancelReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// يتحقق إذا كان الإذن ممنوحًا مسبقًا (Android فقط؛ iOS تُرجع true دائمًا هنا).
  static Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }
}

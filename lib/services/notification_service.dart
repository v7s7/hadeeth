import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationTone {
  gentle('هادئ'),
  motivational('تحفيزي'),
  short('مختصر');

  const NotificationTone(this.labelAr);

  final String labelAr;

  static NotificationTone fromName(String? name) {
    return values.firstWhere(
      (tone) => tone.name == name,
      orElse: () => NotificationTone.gentle,
    );
  }
}

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

  /// رسائل إشعار متنوعة — يتم اختيار واحدة كل يوم دوريًا بحسب النغمة.
  static const Map<NotificationTone, List<String>> _notifBodies = {
    NotificationTone.gentle: [
      'حان وقت قراءة حديث اليوم 📖',
      'دقيقة هادئة مع حديث اليوم تُنير قلبك ☀️',
      'حديث قصير ينتظرك عندما يناسبك الوقت 🌿',
    ],
    NotificationTone.motivational: [
      'سنّة منسية بانتظارك — دقيقتان تُحيي سنة ✨',
      'استمر في سلسلتك اليومية ولا تنقطع عن العلم 🔥',
      'حديث جديد ينتظرك اليوم — تعلّم وبلّغ 📚',
    ],
    NotificationTone.short: [
      'حديث اليوم 📖',
      'لا تنس وردك اليومي ✨',
      'دقيقة للسنّة 🌿',
    ],
  };

  /// يختار رسالة بناءً على يوم السنة (يتغير كل يوم دوريًا).
  static String buildDailyReminderBody({
    String? userName,
    NotificationTone tone = NotificationTone.gentle,
  }) {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final bodies = _notifBodies[tone] ?? _notifBodies[NotificationTone.gentle]!;
    final body = bodies[dayOfYear % bodies.length];
    final name = userName?.trim();
    if (name == null || name.isEmpty) return body;
    return '$name، $body';
  }

  /// يُهيَّأ مرة واحدة في [main] قبل تشغيل التطبيق.
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bahrain'));

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

  /// يطلب إذن الإشعارات من المستخدم.
  static Future<bool> requestPermission() async {
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

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  /// يجدول إشعارًا يوميًا يتكرر في [time] كل يوم مع رسالة متنوعة.
  static Future<void> scheduleDailyReminder(
    TimeOfDay time, {
    String? userName,
    NotificationTone tone = NotificationTone.gentle,
  }) async {
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

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'الحديث المهجور',
      buildDailyReminderBody(userName: userName, tone: tone),
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

  static Future<void> cancelReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

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

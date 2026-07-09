import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

/// معالج الإشعارات في الخلفية (يجب أن يكون دالة علوية، ليس method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // لا نحتاج تهيئة Firebase هنا لأنها ستكون مهيّأة مسبقًا.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase.
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    if (!kIsWeb) {
      // معالج الرسائل في الخلفية.
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // طلب إذن الإشعارات (iOS).
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // اشتراك جميع المستخدمين في topic مشترك حتى يتلقوا إشعارات المشرف.
      await FirebaseMessaging.instance.subscribeToTopic('all_users');

      // إشعارات الواجهة الأمامية: عرض banner + صوت.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  } catch (_) {
    // Firebase غير مهيّأ؛ يستمر التطبيق بالتخزين المحلي.
  }

  // تهيئة نظام الإشعارات المحلية (لا تعمل على الويب).
  if (!kIsWeb) await NotificationService.init();

  runApp(const HadeethApp());
}

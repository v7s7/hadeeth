import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// خيارات Firebase الافتراضية للتطبيق.
///
/// هذا ملف مؤقت (placeholder) بقيم تجريبية، يسمح للتطبيق بالعمل والبناء
/// بدون أي إعداد فعلي لـ Firebase (يستمر التطبيق بالبيانات المحلية فقط).
///
/// لتفعيل Firebase فعليًا:
/// 1) أنشئ مشروعًا على https://console.firebase.google.com وفعّل فيه:
///    - Authentication (طريقة Email/Password)
///    - Firestore Database
/// 2) شغّل الأمر التالي في جذر المشروع:
///      flutterfire configure
///    سيستبدل هذا الأمر هذا الملف بالقيم الحقيقية لمشروعك تلقائيًا.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: 'placeholder-app-id',
    messagingSenderId: 'placeholder-sender-id',
    projectId: 'placeholder-project-id',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: 'placeholder-app-id',
    messagingSenderId: 'placeholder-sender-id',
    projectId: 'placeholder-project-id',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: 'placeholder-app-id',
    messagingSenderId: 'placeholder-sender-id',
    projectId: 'placeholder-project-id',
  );
}

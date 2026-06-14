import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// خيارات Firebase الافتراضية للتطبيق.
///
/// تم ضبط إعدادات الويب (`web`) على مشروع Firebase الحقيقي `hadeeth-19906`.
/// إعدادات Android و iOS ما زالت قيمًا مؤقتة (placeholders) إلى أن يتم تشغيل:
///
///   flutterfire configure
///
/// والذي يستبدلها بقيم مشروعك الحقيقية لكل منصة دون التأثير على إعدادات الويب.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
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
    apiKey: 'AIzaSyAXr6VToHtqa0q47x8lk2wQgdfVFFvEz_A',
    appId: '1:167885922779:web:23ded4eea615102c4207fe',
    messagingSenderId: '167885922779',
    projectId: 'hadeeth-19906',
    authDomain: 'hadeeth-19906.firebaseapp.com',
    storageBucket: 'hadeeth-19906.firebasestorage.app',
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

# دليل رفع التطبيق على TestFlight

اتبع الخطوات بالترتيب من المحطة (Terminal) في مجلد المشروع.

---

## الخطوة 1 — تثبيت الحزم الجديدة

```bash
flutter pub get
```

---

## الخطوة 2 — توليد ملفات منصة iOS

```bash
flutter create . --project-name hadeeth --org com.hadeeth --platforms=ios
```

> هذا يُولّد مجلد `ios/` دون المساس بـ `lib/` أو ملفات الإعداد.

---

## الخطوة 3 — وضع GoogleService-Info.plist

انقل الملف `GoogleService-Info.plist` (الموجود حاليًا في `lib/`) إلى:

```
ios/Runner/GoogleService-Info.plist
```

يمكنك فعل ذلك من Terminal:

```bash
mv lib/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
```

---

## الخطوة 4 — تثبيت CocoaPods

```bash
cd ios
pod install
cd ..
```

> إذا لم يكن CocoaPods مثبتًا: `sudo gem install cocoapods`

---

## الخطوة 5 — فتح المشروع في Xcode

```bash
open ios/Runner.xcworkspace
```

> **مهم:** افتح `.xcworkspace` وليس `.xcodeproj`

---

## الخطوة 6 — إعداد التوقيع في Xcode

1. في الشريط الجانبي، اختر **Runner** (الجذر).
2. انتقل إلى تبويب **Signing & Capabilities**.
3. ضع علامة على **Automatically manage signing**.
4. من **Team**، اختر حساب Apple Developer الخاص بك (`menuappbh@gmail.com`).
5. تأكد أن **Bundle Identifier** هو: `com.hadeeth.app`

---

## الخطوة 7 — إضافة صلاحية الإشعارات

لا تزال في Xcode، في **Signing & Capabilities**:

1. اضغط **+ Capability**.
2. أضف **Push Notifications** (مطلوبة حتى للإشعارات المحلية على iOS).
3. أضف **Background Modes** ← ضع علامة على **Background fetch** و **Remote notifications**.

---

## الخطوة 8 — رفع رقم الإصدار (اختياري)

في `pubspec.yaml`، غيّر:
```yaml
version: 0.1.0+1
```
إلى رقم أعلى قبل كل رفع جديد على TestFlight.

---

## الخطوة 9 — بناء الأرشيف ورفعه

```bash
flutter build ipa
```

ثم في Xcode:

1. من القائمة العلوية: **Product → Archive**
2. بعد اكتمال البناء، تفتح نافذة **Organizer** تلقائيًا.
3. اضغط **Distribute App**.
4. اختر **App Store Connect** ثم **Upload**.
5. اتبع الخطوات حتى ينتهي الرفع.

---

## الخطوة 10 — إعداد Firebase (إن لم تفعله بعد)

من [Firebase Console - hadeeth-19906](https://console.firebase.google.com/project/hadeeth-19906):

1. **Authentication → Sign-in method**: فعّل **Email/Password**.
2. **Firestore Database**: أنشئ قاعدة بيانات (وضع Production).
3. انشر قواعد الأمان:
   ```bash
   firebase deploy --only firestore:rules
   ```

---

## الخطوة 11 — TestFlight

1. افتح [App Store Connect](https://appstoreconnect.apple.com).
2. انتقل إلى تطبيقك → **TestFlight**.
3. بعد اكتمال معالجة البناء (10-30 دقيقة)، أضف المختبِرين بالبريد الإلكتروني أو رابط عام.

---

## ملاحظات

| الموضوع | التفاصيل |
|---------|---------|
| Bundle ID | `com.hadeeth.app` |
| Firebase Project | `hadeeth-19906` |
| Apple Developer | `menuappbh@gmail.com` |
| Min iOS | 12.0 (افتراضي Flutter) |
| الإشعارات | محلية فقط (لا تحتاج FCM server) |
| تعيين أول مشرف | من Firestore Console → `users/{uid}` → غيّر `role` إلى `superAdmin` |

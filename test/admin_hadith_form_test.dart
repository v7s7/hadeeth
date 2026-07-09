import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hadeeth/models/app_user.dart';
import 'package:hadeeth/models/hadith.dart';
import 'package:hadeeth/models/hadith_category.dart';
import 'package:hadeeth/models/user_role.dart';
import 'package:hadeeth/screens/admin/admin_hadith_form_screen.dart';
import 'package:hadeeth/services/category_repository.dart';
import 'package:hadeeth/services/hadith_repository.dart';
import 'package:hadeeth/services/session_service.dart';

class _FakeCategoryRepository extends CategoryRepository {
  @override
  List<HadithCategory> get categories => const [
        HadithCategory(id: 'salah', nameAr: 'الصلاة', iconKey: 'menu_book_outlined'),
      ];
}

class _FakeHadithRepository extends HadithRepository {
  _FakeHadithRepository(super.categoryRepository);

  Hadith? added;
  Hadith? updated;

  @override
  Hadith? getById(String id) => null;

  @override
  Future<void> addHadith(Hadith hadith) async {
    added = hadith;
  }

  @override
  Future<void> updateHadith(Hadith hadith) async {
    updated = hadith;
  }
}

AppUser _userWithRole(UserRole role) => AppUser(
      id: 'u1',
      email: 'user@example.com',
      displayName: 'Test User',
      role: role,
      isDisabled: false,
      createdAt: DateTime(2026),
    );

/// النموذج طويل جدًا (حقول + فوائد + كلمات غريبة + أسئلة اختبار)، فنكبّر
/// نافذة الاختبار حتى تُبنى كل عناصره (Sliver lists لا تبني ما هو خارج
/// حدود الشاشة).
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness(SessionService session, _FakeCategoryRepository categoryRepo,
    _FakeHadithRepository hadithRepo) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('HOME'))),
      GoRoute(path: '/form', builder: (c, s) => const AdminHadithFormScreen()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionService>.value(value: session),
      ChangeNotifierProvider<CategoryRepository>.value(value: categoryRepo),
      ChangeNotifierProvider<HadithRepository>.value(value: hadithRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('superAdmin: empty submit shows validation errors, no write happens',
      (tester) async {
    _useTallViewport(tester);

    final session = SessionService()..debugSetProfile(_userWithRole(UserRole.superAdmin));
    final categoryRepo = _FakeCategoryRepository();
    final hadithRepo = _FakeHadithRepository(categoryRepo);

    await tester.pumpWidget(_harness(session, categoryRepo, hadithRepo));
    // navigate from home to the form, like a real navigation stack
    final context = tester.element(find.text('HOME'));
    GoRouter.of(context).push('/form');
    await tester.pumpAndSettle();

    expect(find.text('حديث جديد'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'إضافة الحديث'));
    await tester.pumpAndSettle();

    expect(find.text('هذا الحقل مطلوب'), findsWidgets);
    expect(find.text('اختر تصنيفًا'), findsOneWidget);
    expect(hadithRepo.added, isNull);
  });

  testWidgets('superAdmin: filling required fields and submitting publishes directly',
      (tester) async {
    _useTallViewport(tester);

    final session = SessionService()..debugSetProfile(_userWithRole(UserRole.superAdmin));
    final categoryRepo = _FakeCategoryRepository();
    final hadithRepo = _FakeHadithRepository(categoryRepo);

    await tester.pumpWidget(_harness(session, categoryRepo, hadithRepo));
    final context = tester.element(find.text('HOME'));
    GoRouter.of(context).push('/form');
    await tester.pumpAndSettle();

    Future<void> fill(String label, String value) async {
      await tester.enterText(find.widgetWithText(TextFormField, label), value);
    }

    await fill('العنوان', 'عنوان تجريبي');
    await fill('نص الحديث', 'نص الحديث التجريبي');
    await fill('الراوي', 'أبو هريرة');
    await fill('الكتاب المصدر', 'صحيح البخاري');
    await fill('رقم/مرجع الحديث', '123');
    await fill('شرح مختصر', 'شرح مختصر تجريبي');
    await fill('شرح تفصيلي', 'شرح تفصيلي تجريبي أطول من السابق');

    // pick the only category from the dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الصلاة').last);
    await tester.pumpAndSettle();

    // add one benefit, one strange word, and fill the auto-added quiz question
    await tester.tap(find.widgetWithText(TextButton, 'إضافة فائدة'));
    await tester.pumpAndSettle();
    await fill('فائدة 1', 'فائدة تجريبية');

    await tester.tap(find.widgetWithText(TextButton, 'إضافة كلمة'));
    await tester.pumpAndSettle();
    await fill('الكلمة', 'كلمة');
    await fill('المعنى', 'معنى');

    await tester.tap(find.widgetWithText(TextButton, 'إضافة سؤال'));
    await tester.pumpAndSettle();
    await fill('نص السؤال', 'ما معنى هذا الحديث؟');
    for (var i = 1; i <= 4; i++) {
      await fill('الخيار $i', 'خيار $i');
    }
    await fill('شرح الإجابة', 'شرح الإجابة الصحيحة');

    await tester.tap(find.widgetWithText(ElevatedButton, 'إضافة الحديث'));
    await tester.pumpAndSettle();

    expect(hadithRepo.added, isNotNull);
    expect(hadithRepo.added!.title, 'عنوان تجريبي');
    expect(hadithRepo.added!.categoryId, 'salah');
    expect(hadithRepo.added!.benefits, ['فائدة تجريبية']);
    expect(hadithRepo.added!.strangeWords.single.word, 'كلمة');
    expect(hadithRepo.added!.quizQuestions.single.questionText, 'ما معنى هذا الحديث؟');
    // superAdmin publishes directly (goes through repository.addHadith to `hadiths`)
    expect(hadithRepo.added!.status, isNotNull);

    // Screen should have popped back to home after a successful save.
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('حديث جديد'), findsNothing);
  });

  testWidgets('content admin (non-super): sees review banner and review-only button label',
      (tester) async {
    _useTallViewport(tester);

    final session = SessionService()..debugSetProfile(_userWithRole(UserRole.admin));
    final categoryRepo = _FakeCategoryRepository();
    final hadithRepo = _FakeHadithRepository(categoryRepo);

    await tester.pumpWidget(_harness(session, categoryRepo, hadithRepo));
    final context = tester.element(find.text('HOME'));
    GoRouter.of(context).push('/form');
    await tester.pumpAndSettle();

    expect(find.text('إرسال حديث للمراجعة'), findsOneWidget);
    expect(find.text('سيُراجَع هذا الحديث من المشرف العام قبل نشره.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'إرسال للمراجعة'), findsOneWidget);
    // Content admins never get the raw publish-status dropdown.
    expect(find.text('حالة النشر'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/admin/admin_categories_screen.dart';
import '../screens/admin/admin_hadith_form_screen.dart';
import '../screens/admin/admin_hadiths_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_notifications_screen.dart';
import '../screens/admin/admin_pending_category_form_screen.dart';
import '../screens/admin/admin_pending_screen.dart';
import '../screens/admin/admin_submissions_screen.dart';
import '../screens/admin/admin_user_submissions_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/categories/category_hadiths_screen.dart';
import '../screens/hadith_details/hadith_details_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/root/root_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/character_reveal_screen.dart';
import '../screens/welcome/gender_selection_screen.dart';

/// انتقال بالتلاشي — يُستخدم للشاشات التي تحتاج تجربة سلسة بدون انزلاق.
CustomTransitionPage<void> _fadePage(
    GoRouterState state, Widget child, Duration duration) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// خريطة التنقل لكل شاشات التطبيق.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // ── شاشات الترحيب (تلاشٍ سلس بدلاً من الانزلاق) ──────────
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => _fadePage(
        state,
        const GenderSelectionScreen(),
        const Duration(milliseconds: 500),
      ),
    ),
    GoRoute(
      path: '/welcome/reveal',
      pageBuilder: (context, state) => _fadePage(
        state,
        const CharacterRevealScreen(),
        const Duration(milliseconds: 600),
      ),
    ),

    // الشاشة الرئيسية — تلاشٍ خفيف عند القدوم من البداية أو الترحيب
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _fadePage(
        state,
        const RootShell(),
        const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/hadith/:id',
      builder: (context, state) => HadithDetailsScreen(
        hadithId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/quiz/:id',
      builder: (context, state) => QuizScreen(
        hadithId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) => CategoryHadithsScreen(
        categoryId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryScreen(),
    ),

    // ── لوحة التحكم ─────────────────────────────────────────────
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
    ),

    // مشرف عام: إدارة المحتوى المنشور
    GoRoute(
      path: '/admin/hadiths',
      builder: (context, state) => const AdminHadithsScreen(),
    ),
    GoRoute(
      path: '/admin/hadiths/new',
      builder: (context, state) => const AdminHadithFormScreen(),
    ),
    GoRoute(
      path: '/admin/hadiths/:id/edit',
      builder: (context, state) => AdminHadithFormScreen(
        hadithId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoriesScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/admin/users/:uid/submissions',
      builder: (context, state) {
        final uid  = state.pathParameters['uid']!;
        final name = (state.extra as String?) ?? uid;
        return AdminUserSubmissionsScreen(userId: uid, userName: name);
      },
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const AdminNotificationsScreen(),
    ),

    // مشرف عام: مراجعة المقدّمات المعلّقة
    GoRoute(
      path: '/admin/pending',
      builder: (context, state) => const AdminPendingScreen(),
    ),

    // مشرف محتوى: إرسال تصنيف جديد للمراجعة
    GoRoute(
      path: '/admin/pending-category/new',
      builder: (context, state) => const AdminPendingCategoryFormScreen(),
    ),

    // مشرف محتوى: متابعة مقدّماته
    GoRoute(
      path: '/admin/submissions',
      builder: (context, state) => const AdminSubmissionsScreen(),
    ),
  ],
);

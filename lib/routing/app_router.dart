import 'package:go_router/go_router.dart';

import '../screens/admin/admin_categories_screen.dart';
import '../screens/admin/admin_hadith_form_screen.dart';
import '../screens/admin/admin_hadiths_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/categories/category_hadiths_screen.dart';
import '../screens/hadith_details/hadith_details_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/root/root_shell.dart';
import '../screens/splash/splash_screen.dart';

/// خريطة التنقل لكل شاشات التطبيق.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const RootShell(),
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
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
    ),
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
  ],
);

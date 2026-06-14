import 'package:go_router/go_router.dart';

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
  ],
);

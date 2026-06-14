import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
import 'services/category_repository.dart';
import 'services/hadith_repository.dart';
import 'services/local_storage_service.dart';
import 'services/progress_service.dart';
import 'services/session_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// أقصى عرض للتطبيق على الويب، لمحاكاة حجم شاشة الهاتف على المتصفح.
const double _kMobileMaxWidth = 430;

/// جذر التطبيق: المزوّدات، الثيم، التوجيه، والتعريب.
class HadeethApp extends StatelessWidget {
  const HadeethApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProgressService(LocalStorageService())..load(),
        ),
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider(create: (_) => CategoryRepository()),
        ChangeNotifierProvider(
          create: (context) => HadithRepository(context.read<CategoryRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'الحديث المهجور',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();

          final mediaQuery = MediaQuery.of(context);
          final size = mediaQuery.size;
          if (size.width <= _kMobileMaxWidth) return child;

          return ColoredBox(
            color: AppColors.primaryDark,
            child: Center(
              child: Container(
                width: _kMobileMaxWidth,
                height: size.height,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: MediaQuery(
                  data: mediaQuery.copyWith(size: Size(_kMobileMaxWidth, size.height)),
                  child: ClipRect(child: child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

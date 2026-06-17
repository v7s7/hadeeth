import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
import 'services/category_repository.dart';
import 'services/font_size_service.dart';
import 'services/hadith_repository.dart';
import 'services/local_storage_service.dart';
import 'services/progress_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

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
        ChangeNotifierProvider(
          create: (_) => FontSizeService()..load(),
        ),
      ],
      child: Consumer<FontSizeService>(
        builder: (context, fontService, _) {
          return MaterialApp.router(
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
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(fontService.scale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

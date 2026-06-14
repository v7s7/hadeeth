import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
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
      ),
    );
  }
}

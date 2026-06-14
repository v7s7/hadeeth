import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// شاشة البداية: شعار التطبيق واسمه قبل التحويل إلى الشاشة الرئيسية.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/branding/splash_illustration.png',
              width: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'الحديث المهجور',
              style: AppTextStyles.appTitle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'أحاديث صحيحة وسنن منسية',
              style: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

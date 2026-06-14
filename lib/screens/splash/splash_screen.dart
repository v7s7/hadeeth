import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// شاشة البداية: شعار التطبيق واسمه ثم التحويل إلى:
/// - شاشة الترحيب (أول تشغيل)
/// - الشاشة الرئيسية (التشغيلات اللاحقة)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // عرض شاشة البداية لفترة كافية ثم الانتقال.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final storage = LocalStorageService();
    final hasSeenOnboarding = await storage.hasSeenOnboarding();

    if (!mounted) return;
    if (hasSeenOnboarding) {
      context.go('/home');
    } else {
      await storage.markOnboardingComplete();
      context.go('/onboarding');
    }
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
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.menu_book,
                size: 120,
                color: Colors.white54,
              ),
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

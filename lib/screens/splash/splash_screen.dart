import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// شاشة البداية: شعار التطبيق واسمه ثم التحويل إلى:
/// - شاشة اختيار الجنس (أول تشغيل — لم يكمل الترحيب)
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
    final storage = LocalStorageService();

    // يُسخِّن الذاكرة المؤقتة وينتظر الحد الأدنى للعرض بالتوازي.
    // بنهاية الانتظار تكون كل القيم في الذاكرة — لا انتظار إضافي بعدها.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1400)),
      storage.preload(),
    ]);

    if (!mounted) return;
    final completed = LocalStorageService.cachedWelcome ?? false;

    if (completed) {
      context.go('/home');
    } else {
      context.go('/welcome');
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// شاشة البداية: شعار التطبيق واسمه ثم التحويل إلى:
/// - شاشة التعريف الأولى إذا لم تُعرض من قبل
/// - شاشة اختيار الاسم والشخصية إذا لم يكتمل الترحيب
/// - الشاشة الرئيسية بعد إكمال الترحيب
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
    var completedWelcome = LocalStorageService.cachedWelcome ?? false;
    var seenOnboarding = await storage.hasSeenOnboarding();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 6));
        final data = doc.data();
        completedWelcome = data?['completedWelcome'] as bool? ?? false;
        seenOnboarding = data?['completedOnboarding'] as bool? ?? false;
      }
    } catch (_) {
      // إن تعذّر الوصول للحساب نستخدم حالة الجهاز كمسار احتياطي فقط.
    }

    if (!seenOnboarding && !completedWelcome) {
      context.go('/onboarding');
    } else if (completedWelcome) {
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

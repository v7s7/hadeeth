import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// بيانات كل صفحة من صفحات الترحيب.
class _OnboardingPage {
  final String imagePath;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    imagePath: 'assets/images/onboarding/onboarding_daily_reading.png',
    title: 'حديث يومي جديد',
    subtitle:
        'تعلّم حديثًا صحيحًا وسنةً منسيةً كل يوم، مع شرح مبسّط وفوائد عملية.',
  ),
  _OnboardingPage(
    imagePath: 'assets/images/onboarding/onboarding_quiz.png',
    title: 'اختبر نفسك',
    subtitle:
        'بعد كل حديث، اختبر فهمك بأسئلة قصيرة واكسب نقاطًا على كل إجابة صحيحة.',
  ),
  _OnboardingPage(
    imagePath: 'assets/images/onboarding/onboarding_streak.png',
    title: 'حافظ على سلسلتك',
    subtitle:
        'واظب على التعلم يومًا بعد يوم وارتقِ في المستويات لتكسب لقب "عالم السنن".',
  ),
];

/// شاشة الترحيب التي تظهر عند أول تشغيل للتطبيق.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // زر تخطّي
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'تخطّي',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // صفحات الترحيب
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _PageView(page: _pages[index]),
              ),
            ),

            // مؤشرات الصفحات
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // أزرار التنقل
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'ابدأ الآن' : 'التالي'),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _OnboardingPage page;

  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page.imagePath,
            height: 260,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: AppTextStyles.screenTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

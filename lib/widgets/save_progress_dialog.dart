import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_progress.dart';
import '../services/local_storage_service.dart';
import '../theme/app_text_styles.dart';

/// يراقب تقدّم الضيف ويعرض دعوة ودودة لإنشاء حساب — مرة واحدة فقط لكل
/// جهاز، وبعد أول إنجاز حقيقي (تعلّم حديث أو إتمام اختبار) بدل طلبها مسبقًا
/// قبل أن يستثمر المستخدم أي جهد في التطبيق.
class SignupNudge extends StatefulWidget {
  final bool isGuest;
  final UserProgress progress;

  const SignupNudge({
    super.key,
    required this.isGuest,
    required this.progress,
  });

  @override
  State<SignupNudge> createState() => _SignupNudgeState();
}

class _SignupNudgeState extends State<SignupNudge> {
  static bool _handledThisSession = false;

  @override
  void initState() {
    super.initState();
    _maybeTrigger();
  }

  @override
  void didUpdateWidget(SignupNudge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeTrigger();
  }

  void _maybeTrigger() {
    if (_handledThisSession || !widget.isGuest) return;
    final earnedMilestone = widget.progress.learnedHadithIds.isNotEmpty ||
        widget.progress.quizzesCompleted >= 1;
    if (!earnedMilestone) return;

    _handledThisSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShow());
  }

  Future<void> _checkAndShow() async {
    final storage = LocalStorageService();
    if (await storage.hasSeenSignupPrompt()) return;
    await storage.markSignupPromptSeen();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => const _SaveProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SaveProgressDialog extends StatelessWidget {
  const _SaveProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'أحسنت! بداية موفقة',
              style: AppTextStyles.screenTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'أنشئ حسابًا مجانيًا الآن لحفظ تقدمك وسلسلتك اليومية، '
              'ومزامنتها على أجهزتك الأخرى — يستغرق دقيقة واحدة فقط.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/register');
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('إنشاء حساب الآن'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ليس الآن'),
            ),
          ],
        ),
      ),
    );
  }
}

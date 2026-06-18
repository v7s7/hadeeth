import 'package:flutter/material.dart';

import '../models/app_level.dart';
import '../theme/app_text_styles.dart';

/// يعرض المستوى الحالي وشريط التقدم نحو المستوى التالي، مع حركة سلسة
/// تتبع كل تغيّر في نقاط الخبرة بدءًا من القيمة المعروضة حاليًا.
class XpProgressBar extends StatelessWidget {
  final AppLevel currentLevel;
  final AppLevel? nextLevel;
  final int totalXp;
  final double progress;

  const XpProgressBar({
    super.key,
    required this.currentLevel,
    required this.nextLevel,
    required this.totalXp,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final next = nextLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('المستوى ${currentLevel.level}', style: AppTextStyles.caption),
                const SizedBox(width: 6),
                Text(currentLevel.titleAr, style: AppTextStyles.bodyBold),
              ],
            ),
            TweenAnimationBuilder<int>(
              tween: IntTween(end: totalXp),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Text(
                next == null ? '$value XP' : '$value / ${next.xpRequired} XP',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }
}

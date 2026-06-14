import 'package:flutter/material.dart';

import '../models/app_level.dart';
import '../theme/app_text_styles.dart';

/// يعرض المستوى الحالي وشريط التقدم نحو المستوى التالي.
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
            Text(
              next == null ? '$totalXp XP' : '$totalXp / ${next.xpRequired} XP',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

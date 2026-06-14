import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// شعار يعرض عدد أيام سلسلة التعلم اليومية (Streak).
class StreakBadge extends StatelessWidget {
  final int streak;

  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.streak.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.streak, size: 20),
          const SizedBox(width: 6),
          Text(
            '$streak يوم',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.streak),
          ),
        ],
      ),
    );
  }
}

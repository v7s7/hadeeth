import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// شعار صغير يشير إلى أن الحديث من السنن/الأحاديث المهجورة.
class AbandonedBadge extends StatelessWidget {
  const AbandonedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.abandoned.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'مهجور',
        style: AppTextStyles.badge.copyWith(color: AppColors.abandoned),
      ),
    );
  }
}

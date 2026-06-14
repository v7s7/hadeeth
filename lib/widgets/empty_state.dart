import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// حالة عرض عامة عند عدم وجود بيانات (قوائم فارغة، نتائج بحث، إلخ).
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    this.subtitle,
  }) : assert(icon != null || imagePath != null, 'Provide either icon or imagePath');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, width: 140, height: 140)
            else
              Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.sectionTitle, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: AppTextStyles.caption, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

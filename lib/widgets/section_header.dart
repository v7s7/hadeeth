import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// عنوان قسم مع رابط اختياري "عرض الكل".
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('عرض الكل')),
      ],
    );
  }
}

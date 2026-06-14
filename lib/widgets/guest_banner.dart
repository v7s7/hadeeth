import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// تنبيه ودود للضيوف لتشجيعهم على إنشاء حساب لحفظ تقدمهم.
class GuestBanner extends StatelessWidget {
  final String message;

  const GuestBanner({
    super.key,
    this.message = 'سجّل دخولك لحفظ تقدمك وبناء سلسلة تعلمك اليومية.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentDark.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentDark),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

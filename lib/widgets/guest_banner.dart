import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// تنبيه ودود للضيوف لتشجيعهم على إنشاء حساب لحفظ تقدمهم.
///
/// عند تمرير [onTap] يصبح الشريط قابلًا للنقر مع سهم يدل على ذلك — يُستخدم
/// لتوجيه الضيف مباشرة لشاشة إنشاء الحساب من أي مكان يظهر فيه الشريط.
class GuestBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const GuestBanner({
    super.key,
    this.message = 'سجّل دخولك لحفظ تقدمك وبناء سلسلة تعلمك اليومية.',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
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
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left, color: AppColors.accentDark),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

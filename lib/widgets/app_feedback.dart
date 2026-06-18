import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// رسائل عابرة (toast) قصيرة لتأكيد نجاح إجراء — تُعرض عبر [ScaffoldMessenger]
/// الجذري فتبقى ظاهرة حتى عند التنقّل لشاشة أخرى مباشرة بعدها (مثل الانتقال
/// للرئيسية بعد تسجيل الدخول).
///
/// لا تُستخدم لأخطاء التحقق من الحقول — تلك تُعرض كنص ثابت بجانب الحقل
/// نفسه حتى يتسنى للمستخدم تصحيحها، لا في رسالة تختفي تلقائيًا.
class AppFeedback {
  AppFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

import 'package:flutter/material.dart';

import '../models/app_accessory.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// بطاقة عرض إكسسوار واحد — تُستخدم في خزانة الشخصية وأي قائمة اختيار أخرى.
class AccessoryTile extends StatelessWidget {
  final AppAccessory accessory;
  final bool selected;
  final bool unlocked;
  final String hint;
  final VoidCallback? onTap;

  const AccessoryTile({
    super.key,
    required this.accessory,
    required this.selected,
    required this.unlocked,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? accessory.color : AppColors.textMuted;

    return Semantics(
      button: unlocked,
      selected: selected,
      label: '${accessory.nameAr}، $hint',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.18)
                : color.withOpacity(unlocked ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.22),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.36,
                child: Image.asset(accessory.imagePath,
                    width: 36, height: 36, fit: BoxFit.contain),
              ),
              const SizedBox(height: 6),
              Text(
                accessory.nameAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selected ? 'مختار' : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? color : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

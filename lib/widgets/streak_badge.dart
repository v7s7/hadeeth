import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// شعار السلسلة اليومية — أيقونات لهب متحركة، صفر إيموجي.
class StreakBadge extends StatelessWidget {
  final int streak;

  /// نص المضاعف (مثل "×1.5") — يُعرض بأيقونة بولت تحت العداد إن كان غير فارغ.
  final String? multiplierLabel;

  const StreakBadge({
    super.key,
    required this.streak,
    this.multiplierLabel,
  });

  // number of flame icons to render based on tier
  int get _flameCount => streak >= 30 ? 3 : streak >= 14 ? 2 : 1;

  // flame colour intensifies with streak length
  Color get _flameColor {
    if (streak >= 30) return const Color(0xFFFF4500); // fiery orange-red
    if (streak >= 14) return const Color(0xFFFF7200); // deep orange
    if (streak >= 7) return const Color(0xFFFF9500);  // warm orange
    return AppColors.accentDark;                       // muted gold for short streaks
  }

  // whether flames should pulse (only worthwhile for streak ≥ 3)
  bool get _shouldPulse => streak >= 3;

  @override
  Widget build(BuildContext context) {
    final hasBoost = multiplierLabel != null && multiplierLabel!.isNotEmpty;
    final flameColor = _flameColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: hasBoost ? 10 : 12,
        vertical: hasBoost ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            flameColor.withOpacity(hasBoost ? 0.18 : 0.13),
            flameColor.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: hasBoost
            ? Border.all(color: AppColors.accent.withOpacity(0.35), width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── animated flame icon(s) ──────────────────────────────────
              ..._buildFlames(flameColor),
              const SizedBox(width: 5),
              Text(
                '$streak يوم',
                style: AppTextStyles.bodyBold.copyWith(color: flameColor),
              ),
            ],
          ),

          // ── XP boost indicator (bolt icon, no emoji) ───────────────────
          if (hasBoost) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 11, color: AppColors.accent)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.15, 1.15),
                      duration: 850.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 2),
                Text(
                  '$multiplierLabel XP',
                  style:
                      AppTextStyles.badge.copyWith(color: AppColors.accent, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFlames(Color flameColor) {
    return List.generate(_flameCount, (i) {
      final flame = Icon(
        Icons.local_fire_department,
        color: flameColor,
        size: 18,
      );

      if (!_shouldPulse) return flame;

      return flame
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.88, 0.88),
            end: const Offset(1.12, 1.12),
            duration: Duration(milliseconds: 620 + i * 160),
            curve: Curves.easeInOut,
          )
          .tint(
            color: Colors.orange.withOpacity(0.12),
            duration: Duration(milliseconds: 620 + i * 160),
          );
    });
  }
}

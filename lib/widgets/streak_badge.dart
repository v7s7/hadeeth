import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// شعار السلسلة اليومية — أيقونة لهب مرسومة ومتحركة بنفس هوية التطبيق.
class StreakBadge extends StatelessWidget {
  final int streak;

  /// نص المضاعف (مثل "×1.5") — يُعرض بأيقونة بولت تحت العداد إن كان غير فارغ.
  final String? multiplierLabel;

  const StreakBadge({
    super.key,
    required this.streak,
    this.multiplierLabel,
  });

  // number of flame echoes to render based on tier
  int get _flameCount => streak >= 30 ? 3 : streak >= 14 ? 2 : 1;

  // flame colour intensifies with streak length
  Color get _flameColor {
    if (streak >= 30) return const Color(0xFFFF4500); // fiery orange-red
    if (streak >= 14) return const Color(0xFFFF7200); // deep orange
    if (streak >= 7) return const Color(0xFFFF9500); // warm orange
    return AppColors.accentDark; // muted gold for short streaks
  }

  // whether flames should pulse (only worthwhile for streak ≥ 3)
  bool get _shouldPulse => streak >= 3;

  @override
  Widget build(BuildContext context) {
    final hasBoost = multiplierLabel != null && multiplierLabel!.isNotEmpty;
    final flameColor = _flameColor;

    return Semantics(
      label: hasBoost
          ? 'سلسلة القراءة $streak يوم، مضاعف الخبرة $multiplierLabel'
          : 'سلسلة القراءة $streak يوم',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: hasBoost ? 10 : 12,
          vertical: hasBoost ? 6 : 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              flameColor.withOpacity(hasBoost ? 0.20 : 0.15),
              AppColors.accentLight.withOpacity(0.24),
              flameColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (hasBoost ? AppColors.accent : flameColor).withOpacity(0.34),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: flameColor.withOpacity(hasBoost ? 0.18 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedStreakIcon(
                  color: flameColor,
                  echoCount: _flameCount,
                  animated: _shouldPulse,
                ),
                const SizedBox(width: 6),
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
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.accent,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedStreakIcon extends StatelessWidget {
  final Color color;
  final int echoCount;
  final bool animated;

  const _AnimatedStreakIcon({
    required this.color,
    required this.echoCount,
    required this.animated,
  });

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox(
      width: 24 + (echoCount - 1) * 7,
      height: 24,
      child: CustomPaint(
        painter: _StreakFlamePainter(
          color: color,
          echoCount: echoCount,
        ),
      ),
    );

    if (!animated) return icon;

    return icon
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1.08, 1.08),
          duration: 760.ms,
          curve: Curves.easeInOut,
        )
        .shimmer(
          color: AppColors.accentLight.withOpacity(0.45),
          duration: 1500.ms,
          angle: math.pi / 8,
        );
  }
}

class _StreakFlamePainter extends CustomPainter {
  final Color color;
  final int echoCount;

  const _StreakFlamePainter({
    required this.color,
    required this.echoCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = echoCount - 1; index >= 0; index--) {
      final dx = index * 7.0;
      final opacity = index == 0 ? 1.0 : 0.30 - (index * 0.05);
      _paintFlame(
        canvas,
        Rect.fromLTWH(dx, 1.5 + index, 21, 21 - index),
        color.withOpacity(opacity.clamp(0.16, 1.0).toDouble()),
      );
    }
  }

  void _paintFlame(Canvas canvas, Rect rect, Color paintColor) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..cubicTo(rect.right, rect.top + rect.height * 0.30, rect.right,
          rect.top + rect.height * 0.68, rect.center.dx, rect.bottom)
      ..cubicTo(rect.left, rect.top + rect.height * 0.70, rect.left,
          rect.top + rect.height * 0.34, rect.center.dx, rect.top)
      ..close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentLight.withOpacity(0.92),
          paintColor,
          AppColors.accentDark.withOpacity(0.72),
        ],
      ).createShader(rect);
    canvas.drawPath(path, outerPaint);

    final innerRect = rect.deflate(rect.width * 0.27);
    final innerPath = Path()
      ..moveTo(innerRect.center.dx, innerRect.top + innerRect.height * 0.05)
      ..cubicTo(innerRect.right, innerRect.top + innerRect.height * 0.45,
          innerRect.right, innerRect.bottom, innerRect.center.dx,
          innerRect.bottom)
      ..cubicTo(innerRect.left, innerRect.top + innerRect.height * 0.72,
          innerRect.left, innerRect.top + innerRect.height * 0.48,
          innerRect.center.dx, innerRect.top + innerRect.height * 0.05)
      ..close();

    canvas.drawPath(
      innerPath,
      Paint()..color = Colors.white.withOpacity(0.36),
    );
  }

  @override
  bool shouldRepaint(covariant _StreakFlamePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.echoCount != echoCount;
  }
}

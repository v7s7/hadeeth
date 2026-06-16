import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/local_storage_service.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// بطاقة الهدف اليومي — تصميم لعبة كاملة الحركة، صفر إيموجي.
class DailyGoalCard extends StatefulWidget {
  final ProgressService progressService;
  const DailyGoalCard({super.key, required this.progressService});

  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard>
    with TickerProviderStateMixin {
  // ── breathing glow on the card border (always)
  late AnimationController _breathCtrl;
  // ── sparkle burst when goal is completed (one-shot)
  late AnimationController _celebCtrl;

  bool _wasDone = false;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _wasDone = _computeDone();
    if (_wasDone) _celebCtrl.value = 1.0; // already done: no burst on load
  }

  @override
  void didUpdateWidget(DailyGoalCard old) {
    super.didUpdateWidget(old);
    final isDone = _computeDone();
    if (isDone && !_wasDone) {
      _celebCtrl.forward(from: 0);
    }
    _wasDone = isDone;
  }

  bool _computeDone() {
    final goal = LocalStorageService.cachedDailyGoal ?? 3;
    final read = widget.progressService.dailyHadithReadCount;
    return read >= goal;
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = LocalStorageService.cachedDailyGoal ?? 3;
    final read = widget.progressService.dailyHadithReadCount;
    final done = read >= goal;
    final fraction = (read / goal).clamp(0.0, 1.0);
    final multiplier = widget.progressService.streakMultiplier;
    final multLabel = widget.progressService.streakMultiplierLabel;
    final hasBoost = multiplier > 1.0;
    final streak = widget.progressService.progress.currentStreak;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathCtrl, _celebCtrl]),
      builder: (context, _) {
        final breath = _breathCtrl.value; // 0..1, eased

        final borderColor = done
            ? AppColors.success.withOpacity(0.30 + breath * 0.28)
            : hasBoost
                ? AppColors.accent.withOpacity(0.28 + breath * 0.18)
                : AppColors.primary.withOpacity(0.20 + breath * 0.10);

        final glowColor =
            done ? AppColors.success : hasBoost ? AppColors.accent : null;
        final glowOpacity = done
            ? 0.16 + breath * 0.12
            : hasBoost
                ? 0.07 + breath * 0.07
                : 0.0;

        return Stack(
          children: [
            // ── main card ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: done
                      ? [const Color(0xFF0B2518), const Color(0xFF071810)]
                      : hasBoost
                          ? [const Color(0xFF1B1700), const Color(0xFF0C0D00)]
                          : [const Color(0xFF0C1A22), const Color(0xFF071018)],
                ),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: glowColor != null && glowOpacity > 0
                    ? [
                        BoxShadow(
                          color: glowColor.withOpacity(glowOpacity),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Header(done: done, hasBoost: hasBoost, multLabel: multLabel, streak: streak),
                    const SizedBox(height: 18),
                    _GemRow(goal: goal, read: read, done: done),
                    const SizedBox(height: 16),
                    _ProgressBarWidget(fraction: fraction, done: done),
                    const SizedBox(height: 10),
                    _Footer(done: done, read: read, goal: goal, hasBoost: hasBoost),
                  ],
                ),
              ),
            ),

            // ── celebration sparkle burst (one-shot) ───────────────────────
            if (_celebCtrl.isAnimating || (_celebCtrl.value > 0 && _celebCtrl.value < 1))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SparklesPainter(
                      t: _celebCtrl.value,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool done;
  final bool hasBoost;
  final String multLabel;
  final int streak;

  const _Header({
    required this.done,
    required this.hasBoost,
    required this.multLabel,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // icon: flag → check (spring transition)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: done
              ? Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('done'),
                  size: 30,
                  color: AppColors.success,
                )
              : Container(
                  key: const ValueKey('goal'),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flag_rounded, size: 17,
                      color: AppColors.primary.withOpacity(0.80)),
                ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            done ? 'أكملت هدفك اليوم' : 'هدف اليوم',
            key: ValueKey(done),
            style: AppTextStyles.bodyBold.copyWith(
              color: done ? AppColors.success : Colors.white.withOpacity(0.88),
              fontSize: 15,
            ),
          ),
        ),
        const Spacer(),
        if (hasBoost) _BoostBadge(label: multLabel, streak: streak),
      ],
    );
  }
}

// ── Boost Badge (no emoji — animated flame icons) ─────────────────────────────

class _BoostBadge extends StatelessWidget {
  final String label;
  final int streak;

  const _BoostBadge({required this.label, required this.streak});

  int get _flameCount => streak >= 30 ? 3 : streak >= 14 ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.accentDark.withOpacity(0.13),
        border: Border.all(color: AppColors.accent.withOpacity(0.40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // stacked flame icons with staggered pulse
          ...List.generate(_flameCount, (i) {
            return Icon(Icons.local_fire_department,
                    color: AppColors.accent, size: 15)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.80, 0.80),
                  end: const Offset(1.22, 1.22),
                  duration: Duration(milliseconds: 650 + i * 180),
                  curve: Curves.easeInOut,
                );
          }),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: 700.ms,
          duration: 2200.ms,
          color: AppColors.accent.withOpacity(0.14),
        );
  }
}

// ── Gem Row ───────────────────────────────────────────────────────────────────

class _GemRow extends StatelessWidget {
  final int goal;
  final int read;
  final bool done;

  const _GemRow({required this.goal, required this.read, required this.done});

  @override
  Widget build(BuildContext context) {
    final count = goal.clamp(1, 10);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _Gem(filled: i < read, done: done, index: i),
      )),
    );
  }
}

class _Gem extends StatelessWidget {
  final bool filled;
  final bool done;
  final int index;

  const _Gem({required this.filled, required this.done, required this.index});

  @override
  Widget build(BuildContext context) {
    // easeOutBack gives a sweet spring overshoot on color/shadow when filled
    return AnimatedContainer(
      duration: Duration(milliseconds: 380 + index * 45),
      curve: Curves.easeOutBack,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: filled
            ? RadialGradient(
                center: const Alignment(-0.35, -0.35),
                radius: 0.9,
                colors: done
                    ? [const Color(0xFF66BB6A), const Color(0xFF2E7D32)]
                    : [AppColors.accent, AppColors.accentDark],
              )
            : RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.0),
                ],
              ),
        border: Border.all(
          color: filled
              ? (done ? AppColors.success : AppColors.accent).withOpacity(0.85)
              : Colors.white.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: (done ? AppColors.success : AppColors.accent)
                      .withOpacity(0.42),
                  blurRadius: 10,
                  spreadRadius: 1.5,
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: filled
              ? Icon(
                  done ? Icons.check_rounded : Icons.circle,
                  key: ValueKey('filled-$done'),
                  size: done ? 14 : 9,
                  color: Colors.white.withOpacity(0.95),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }
}

// ── Shimmer Progress Bar (own StatefulWidget to decouple from parent's ticker)

class _ProgressBarWidget extends StatefulWidget {
  final double fraction;
  final bool done;

  const _ProgressBarWidget({required this.fraction, required this.done});

  @override
  State<_ProgressBarWidget> createState() => _ProgressBarWidgetState();
}

class _ProgressBarWidgetState extends State<_ProgressBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) => _ProgressBarPainter(
        fraction: widget.fraction,
        done: widget.done,
        shimmer: _shimmerCtrl.value,
      ),
    );
  }
}

class _ProgressBarPainter extends StatelessWidget {
  final double fraction;
  final bool done;
  final double shimmer; // 0..1

  const _ProgressBarPainter(
      {required this.fraction, required this.done, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalW = constraints.maxWidth;
      const trackH = 8.0;
      const orbD = 16.0;
      const totalH = orbD;
      final filledW = fraction * totalW;

      return SizedBox(
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // ── track background
            Positioned(
              left: 0,
              right: 0,
              top: (totalH - trackH) / 2,
              height: trackH,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),

            // ── filled portion + shimmer sweep
            if (fraction > 0)
              Positioned(
                left: 0,
                top: (totalH - trackH) / 2,
                height: trackH,
                width: filledW,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(
                    painter: _ShimmerFillPainter(shimmer: shimmer, done: done),
                  ),
                ),
              ),

            // ── glowing orb at the leading edge (in-progress only)
            if (fraction > 0.03 && fraction < 0.98 && !done)
              Positioned(
                left: filledW - orbD / 2,
                top: 0,
                width: orbD,
                height: orbD,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFE57F), AppColors.accentDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.68),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 8, color: Colors.white),
                ),
              ),

            // ── done indicator: filled orb at right end
            if (done)
              Positioned(
                right: 0,
                top: (totalH - orbD) / 2,
                width: orbD,
                height: orbD,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.55),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ShimmerFillPainter extends CustomPainter {
  final double shimmer; // 0..1
  final bool done;
  const _ShimmerFillPainter({required this.shimmer, required this.done});

  @override
  void paint(Canvas canvas, Size size) {
    // base gradient fill
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: done
            ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
            : [AppColors.accentDark, AppColors.accent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    // moving highlight sweep
    final sweepX = shimmer * (size.width + 70) - 35;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.26),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(
          Rect.fromLTWH(sweepX - 28, 0, 56, size.height));
    canvas.drawRect(Rect.fromLTWH(sweepX - 28, 0, 56, size.height), sweepPaint);
  }

  @override
  bool shouldRepaint(_ShimmerFillPainter old) =>
      old.shimmer != shimmer || old.done != done;
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool done;
  final int read;
  final int goal;
  final bool hasBoost;

  const _Footer(
      {required this.done,
      required this.read,
      required this.goal,
      required this.hasBoost});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          '$read / $goal أحاديث',
          style: AppTextStyles.caption.copyWith(
            color: done
                ? AppColors.success.withOpacity(0.75)
                : Colors.white.withOpacity(0.35),
          ),
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: done
              ? Text(
                  'واصل غدًا',
                  key: const ValueKey('done'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success.withOpacity(0.60),
                    fontSize: 11,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 900.ms)
              : hasBoost
                  ? Row(
                      key: const ValueKey('boost'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt,
                            size: 12,
                            color: AppColors.accent.withOpacity(0.65)),
                        const SizedBox(width: 3),
                        Text(
                          'مضاعف XP نشط',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent.withOpacity(0.60),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}

// ── Sparkle celebration (diamond particles, CustomPainter) ────────────────────

class _SparklesPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  static const int _count = 14;

  const _SparklesPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final maxDist =
        math.sqrt(size.width * size.width + size.height * size.height) / 1.8;
    final rng = math.Random(77); // fixed seed → stable particle pattern
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _count; i++) {
      final angle = (i / _count) * 2 * math.pi + rng.nextDouble() * 0.45;
      final speed = 0.55 + rng.nextDouble() * 0.45;
      final dist = maxDist * t * speed;
      final opacity = ((1 - t) * 1.3).clamp(0.0, 1.0);
      final radius = (3.5 + rng.nextDouble() * 4.5) * (1 - t);

      if (opacity <= 0 || radius <= 0) continue;

      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;

      paint.color = color.withOpacity(opacity);

      // 4-pointed diamond
      canvas.drawPath(
        Path()
          ..moveTo(px, py - radius)
          ..lineTo(px + radius * 0.52, py)
          ..lineTo(px, py + radius)
          ..lineTo(px - radius * 0.52, py)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.t != t;
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// يعرض تراكبًا احتفاليًا iOS-style عند تعلّم حديث جديد.
Future<void> showCompletionOverlay({
  required BuildContext context,
  required int xpGained,
  required int newStreak,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    transitionBuilder: (_, __, ___, child) => child,
    pageBuilder: (_, __, ___) =>
        _CompletionOverlay(xpGained: xpGained, newStreak: newStreak),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CompletionOverlay extends StatefulWidget {
  final int xpGained;
  final int newStreak;
  const _CompletionOverlay({required this.xpGained, required this.newStreak});

  @override
  State<_CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<_CompletionOverlay>
    with TickerProviderStateMixin {

  // ── Entrance (handles backdrop + card + checkmark + content) ─────────────
  late final AnimationController _enterCtrl;
  late final Animation<double> _backdropProgress; // 0→1, drives blur + dim
  late final Animation<double> _cardScale;        // 0.82→1.0, easeOutBack
  late final Animation<double> _cardFade;         // 0→1, early
  late final Animation<double> _checkScale;       // 0→1, elasticOut
  late final Animation<double> _contentFade;      // 0→1, late
  late final Animation<double> _contentSlide;     // 8→0 px, late

  // ── Fire pulse (gentle, repeating) ───────────────────────────────────────
  late final AnimationController _fireCtrl;
  late final Animation<double> _fireScale;

  // ── XP counter ───────────────────────────────────────────────────────────
  late final AnimationController _xpCtrl;
  late final Animation<int> _xpCount;

  // ── Sparkle burst ────────────────────────────────────────────────────────
  late final AnimationController _burstCtrl;
  late final List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();

    // ── Entrance ──────────────────────────────────────────────────────────
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _backdropProgress = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0.0, 0.30, curve: Curves.easeOut)),
    );
    _cardScale = Tween(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0.04, 0.68, curve: Curves.easeOutBack)),
    );
    _cardFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0.04, 0.38)),
    );
    _checkScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0.35, 1.0, curve: Curves.elasticOut)),
    );
    _contentFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0.62, 1.0, curve: Curves.easeOut)),
    );
    _contentSlide = Tween(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0.62, 1.0, curve: Curves.easeOut)),
    );

    // ── Fire pulse ────────────────────────────────────────────────────────
    _fireCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _fireScale = Tween(begin: 0.95, end: 1.06).animate(
      CurvedAnimation(parent: _fireCtrl, curve: Curves.easeInOut),
    );

    // ── XP counter ────────────────────────────────────────────────────────
    _xpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _xpCount = IntTween(begin: 0, end: widget.xpGained).animate(
      CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOut),
    );

    // ── Sparkle burst ─────────────────────────────────────────────────────
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    final rng = math.Random();
    _sparkles = List.generate(20, (i) => _Sparkle(rng, i, 20));

    // ── Sequence ──────────────────────────────────────────────────────────
    _enterCtrl.forward().then((_) => _xpCtrl.forward());

    // Burst fires when checkmark arrives (~35% through 1000ms = ~350ms)
    Future.delayed(const Duration(milliseconds: 370), () {
      if (mounted) _burstCtrl.forward();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _fireCtrl.dispose();
    _xpCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Frosted blur backdrop ──────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backdropProgress,
              builder: (_, __) {
                final t = _backdropProgress.value;
                return BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 14 * t,
                    sigmaY: 14 * t,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.46 * t),
                  ),
                );
              },
            ),
          ),

          // ── Sparkle burst ──────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _burstCtrl,
              builder: (_, __) => CustomPaint(
                painter: _SparklePainter(
                  progress: _burstCtrl.value,
                  sparkles: _sparkles,
                  // Approximate card-top-center, where the checkmark sits
                  center: Offset(size.width / 2, size.height * 0.37),
                ),
              ),
            ),
          ),

          // ── Card ────────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, __) => Center(
              child: Opacity(
                opacity: _cardFade.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card content ───────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.11),
            blurRadius: 52,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(26, 34, 26, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Checkmark ─────────────────────────────────────────────────
          ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.26),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Title ─────────────────────────────────────────────────────
          Text(
            'أحسنت!',
            style: GoogleFonts.tajawal(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'تعلّمت هذا الحديث وحفظته في صدرك',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 22),

          // ── Streak + XP (slide & fade in) ─────────────────────────────
          AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, child) => Opacity(
              opacity: _contentFade.value,
              child: Transform.translate(
                offset: Offset(0, _contentSlide.value),
                child: child,
              ),
            ),
            child: Column(
              children: [
                // Streak pill
                _buildStreakPill(),
                const SizedBox(height: 12),
                // XP badge
                AnimatedBuilder(
                  animation: _xpCount,
                  builder: (_, __) => _buildXpBadge(_xpCount.value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ── Continue button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'متابعة',
                style: GoogleFonts.tajawal(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDDB3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated fire emoji
          AnimatedBuilder(
            animation: _fireCtrl,
            builder: (_, child) => Transform.scale(
              scale: _fireScale.value,
              child: child,
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.newStreak} ${_dayLabel(widget.newStreak)}',
                style: GoogleFonts.tajawal(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFD84315),
                  height: 1.1,
                ),
              ),
              Text(
                'سلسلة متواصلة',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFFBF360C).withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpBadge(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent, size: 17),
          const SizedBox(width: 5),
          Text(
            '+$xp XP',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.accentDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sparkle burst ────────────────────────────────────────────────────────────

class _Sparkle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  static const _palette = [
    AppColors.primary,
    AppColors.accent,
    Color(0xFF26C6DA),
    Color(0xFFFF8A65),
    Color(0xFFCE93D8),
    Color(0xFF81C784),
    Color(0xFFFFD54F),
    Color(0xFF80DEEA),
  ];

  _Sparkle(math.Random rng, int index, int total)
      : angle = (index / total) * math.pi * 2 + rng.nextDouble() * 0.5,
        speed = 52 + rng.nextDouble() * 62,
        size = 3.5 + rng.nextDouble() * 4.5,
        color = _palette[rng.nextInt(_palette.length)];
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final List<_Sparkle> sparkles;
  final Offset center;

  const _SparklePainter({
    required this.progress,
    required this.sparkles,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final t = Curves.easeOut.transform(progress);

    for (final s in sparkles) {
      final dist = t * s.speed;
      final dx = math.cos(s.angle) * dist;
      final dy = math.sin(s.angle) * dist;

      // Quick fade in, slow fade out
      final opacity = (progress < 0.18
              ? progress / 0.18
              : 1.0 - ((progress - 0.18) / 0.82))
          .clamp(0.0, 1.0);

      if (opacity <= 0.02) continue;

      canvas.drawCircle(
        Offset(center.dx + dx, center.dy + dy),
        s.size * (1.0 - t * 0.45),
        Paint()
          ..color = s.color.withOpacity(opacity * 0.88)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}

// ── helpers ───────────────────────────────────────────────────────────────────

String _dayLabel(int n) {
  if (n == 1) return 'يوم';
  if (n == 2) return 'يومان';
  if (n >= 3 && n <= 10) return 'أيام';
  return 'يوم';
}

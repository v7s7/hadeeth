import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/levels_data.dart';
import '../models/app_accessory.dart';
import '../models/app_characters.dart';
import 'character_avatar.dart';
import '../models/app_level.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kGold      = Color(0xFFFCD34D);
const _kGoldMid   = Color(0xFFF59E0B);
const _kGoldDeep  = Color(0xFFD97706);
const _kTeal      = Color(0xFF2DD4BF);
const _kCardTop   = Color(0xFF1C2340);
const _kCardBot   = Color(0xFF0D1120);
const _kFire      = Color(0xFFFF6B35);
const _kFireDeep  = Color(0xFFD84315);

/// يعرض تراكبًا احتفاليًا عند تعلّم حديث جديد — بطاقة داكنة، شخصية فوقها،
/// عداد XP متحرك، شريط تقدّم المستوى، ولحظة ارتقاء حين تجاوز المستوى.
Future<void> showCompletionOverlay({
  required BuildContext context,
  required int xpGained,
  required int newStreak,
  required int totalXpAfter,
  required int levelBefore,
  required int levelAfter,
  CharacterOption? character,
  AppAccessory? accessory,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    transitionBuilder: (_, __, ___, child) => child,
    pageBuilder: (_, __, ___) => _CompletionOverlay(
      xpGained: xpGained,
      newStreak: newStreak,
      totalXpAfter: totalXpAfter,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      character: character,
      accessory: accessory,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CompletionOverlay extends StatefulWidget {
  final int xpGained;
  final int newStreak;
  final int totalXpAfter;
  final int levelBefore;
  final int levelAfter;
  final CharacterOption? character;
  final AppAccessory? accessory;

  const _CompletionOverlay({
    required this.xpGained,
    required this.newStreak,
    required this.totalXpAfter,
    required this.levelBefore,
    required this.levelAfter,
    required this.character,
    required this.accessory,
  });

  @override
  State<_CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<_CompletionOverlay>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _xpCtrl;
  late final AnimationController _fireCtrl;
  late final AnimationController _levelUpCtrl;
  late final AnimationController _floatCtrl;

  // ── Entrance ─────────────────────────────────────────────────────────────
  late final Animation<double> _backdropBlur;
  late final Animation<double> _backdropDim;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _charScale;
  late final Animation<double> _contentFade;
  late final Animation<double> _contentSlide;
  late final Animation<double> _btnFade;

  // ── XP ───────────────────────────────────────────────────────────────────
  late final Animation<int>    _xpCount;
  late final Animation<double> _barFill;

  // ── Level-up ─────────────────────────────────────────────────────────────
  late final Animation<double> _lvlScale;
  late final Animation<double> _lvlFade;

  // ── Float ────────────────────────────────────────────────────────────────
  late final Animation<double> _float;

  // ── Confetti particles ────────────────────────────────────────────────────
  late final List<_Particle> _particles;

  bool get _didLevelUp => widget.levelAfter > widget.levelBefore;

  double get _progressBefore =>
      levelProgress(widget.totalXpAfter - widget.xpGained);
  double get _progressAfter => levelProgress(widget.totalXpAfter);

  AppLevel  get _currentLevel => levelForXp(widget.totalXpAfter);
  AppLevel? get _nextLevel    => nextLevelForXp(widget.totalXpAfter);

  int get _xpToNext {
    final n = _nextLevel;
    return n != null ? n.xpRequired - widget.totalXpAfter : 0;
  }

  @override
  void initState() {
    super.initState();

    // ── Entrance (1100 ms) ────────────────────────────────────────────────
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));

    _backdropBlur = _t(0.0, 1.0, 0.00, 0.28, Curves.easeOut);
    _backdropDim  = _t(0.0, 1.0, 0.00, 0.35, Curves.easeOut);
    _cardSlide    = _t(60.0, 0.0, 0.08, 0.68, Curves.easeOutCubic);
    _cardFade     = _t(0.0, 1.0, 0.06, 0.42, Curves.easeOut);
    _charScale    = _t(0.0, 1.0, 0.25, 0.88, Curves.elasticOut);
    _contentFade  = _t(0.0, 1.0, 0.55, 1.00, Curves.easeOut);
    _contentSlide = _t(12.0, 0.0, 0.55, 1.00, Curves.easeOut);
    _btnFade      = _t(0.0, 1.0, 0.82, 1.00, Curves.easeOut);

    // ── Confetti burst ────────────────────────────────────────────────────
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    final rng = math.Random();
    _particles = List.generate(38, (i) => _Particle(rng, i, 38));

    // ── XP counter + bar ─────────────────────────────────────────────────
    _xpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _xpCount = IntTween(begin: 0, end: widget.xpGained).animate(
        CurvedAnimation(
            parent: _xpCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));

    final barTarget = _didLevelUp ? 1.0 : _progressAfter;
    _barFill = Tween(begin: _progressBefore, end: barTarget).animate(
        CurvedAnimation(
            parent: _xpCtrl,
            curve: const Interval(0.15, 1.0, curve: Curves.easeInOut)));

    // ── Fire pulse ────────────────────────────────────────────────────────
    _fireCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    // ── Level-up flash (if applicable) ────────────────────────────────────
    _levelUpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _lvlScale = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _levelUpCtrl, curve: Curves.elasticOut));
    _lvlFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _levelUpCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    // ── Gentle character float ────────────────────────────────────────────
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _float = Tween(begin: -4.0, end: 4.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // ── Sequence ──────────────────────────────────────────────────────────
    _enterCtrl.forward();

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _confettiCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1050), () {
      if (mounted) _xpCtrl.forward();
    });
    if (_didLevelUp) {
      Future.delayed(const Duration(milliseconds: 2300), () {
        if (mounted) _levelUpCtrl.forward();
      });
    }
  }

  // Helper: Tween<double> with interval + curve via _enterCtrl
  Animation<double> _t(double begin, double end, double i0, double i1,
      Curve curve) {
    return Tween(begin: begin, end: end).animate(CurvedAnimation(
        parent: _enterCtrl, curve: Interval(i0, i1, curve: curve)));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _confettiCtrl.dispose();
    _xpCtrl.dispose();
    _fireCtrl.dispose();
    _levelUpCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Frosted backdrop ─────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _enterCtrl,
              builder: (_, __) => BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 18 * _backdropBlur.value,
                  sigmaY: 18 * _backdropBlur.value,
                ),
                child: Container(
                  color: const Color(0xFF050810)
                      .withOpacity(0.72 * _backdropDim.value),
                ),
              ),
            ),
          ),

          // ── Islamic confetti ─────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                  progress: _confettiCtrl.value,
                  particles: _particles,
                  origin: Offset(size.width / 2, size.height * 0.3),
                ),
              ),
            ),
          ),

          // ── Card + character ─────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: MediaQuery.paddingOf(context).top + 16,
              ),
              child: AnimatedBuilder(
                animation: _enterCtrl,
                builder: (_, child) => Opacity(
                  opacity: _cardFade.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, _cardSlide.value),
                    child: child,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _buildCard(),
                    ),
                    Positioned(top: 0, child: _buildCharacter()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Character ─────────────────────────────────────────────────────────────

  Widget _buildCharacter() {
    return AnimatedBuilder(
      animation: Listenable.merge([_enterCtrl, _floatCtrl]),
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.scale(
          scale: _charScale.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gold radial glow
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x55FCD34D),
                      Color(0x22F59E0B),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              if (widget.character != null)
                CharacterAvatar(
                  character: widget.character!,
                  height: 140,
                  accessory: widget.accessory,
                )
              else
                const SizedBox(height: 140, width: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kCardTop, _kCardBot],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _kGold.withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 60,
              offset: const Offset(0, 24)),
          BoxShadow(
              color: _kGold.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: AnimatedBuilder(
        animation: _enterCtrl,
        builder: (_, child) => Opacity(
          opacity: _contentFade.value,
          child: Transform.translate(
              offset: Offset(0, _contentSlide.value), child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'أحسنتَ!',
              style: GoogleFonts.tajawal(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _kGold,
                  letterSpacing: -0.4,
                  height: 1.1),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 6),
            Text(
              'تعلّمت حديثًا جديدًا وحفظته',
              style: GoogleFonts.tajawal(
                  fontSize: 14, color: Colors.white.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            _buildDivider(),
            const SizedBox(height: 18),

            // Streak + XP tiles
            Row(children: [
              Expanded(child: _buildStreakTile()),
              const SizedBox(width: 12),
              Expanded(child: _buildXpTile()),
            ]),

            const SizedBox(height: 18),

            // XP progress bar
            _buildXpBar(),

            // Level-up moment
            if (_didLevelUp) ...[
              const SizedBox(height: 14),
              _buildLevelUpBanner(),
            ],

            const SizedBox(height: 22),

            // Button
            AnimatedBuilder(
              animation: _enterCtrl,
              builder: (_, child) =>
                  Opacity(opacity: _btnFade.value, child: child),
              child: _buildButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            _kGold.withOpacity(0.25),
            Colors.transparent,
          ]),
        ),
      );

  // ── Streak tile ───────────────────────────────────────────────────────────

  Widget _buildStreakTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kFire.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kFire.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _fireCtrl,
            builder: (_, child) => Transform.scale(
              scale: 0.92 + 0.12 * _fireCtrl.value,
              child: child,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                size: 34, color: _kFire),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.newStreak}',
            style: GoogleFonts.tajawal(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _kFire,
                height: 1.1),
          ),
          Text(
            _dayLabel(widget.newStreak),
            style: GoogleFonts.tajawal(
                fontSize: 11,
                color: _kFireDeep.withOpacity(0.85),
                fontWeight: FontWeight.w600),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ── XP tile ───────────────────────────────────────────────────────────────

  Widget _buildXpTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kGold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 34, color: _kGold),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _xpCount,
            builder: (_, __) => Text(
              '+${_xpCount.value}',
              style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _kGold,
                  height: 1.1),
            ),
          ),
          Text(
            'نقطة XP',
            style: GoogleFonts.tajawal(
                fontSize: 11,
                color: _kGoldDeep.withOpacity(0.9),
                fontWeight: FontWeight.w600),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ── XP progress bar ───────────────────────────────────────────────────────

  Widget _buildXpBar() {
    final current  = _currentLevel;
    final isMaxLvl = _nextLevel == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المستوى ${current.level} • ${current.titleAr}',
              style: GoogleFonts.tajawal(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kTeal),
              textDirection: TextDirection.rtl,
            ),
            if (!isMaxLvl)
              Text(
                '$_xpToNext XP للمستوى التالي',
                style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35)),
                textDirection: TextDirection.rtl,
              )
            else
              Text(
                'المستوى الأعلى 🏆',
                style: GoogleFonts.tajawal(
                    fontSize: 11, color: _kGold.withOpacity(0.7)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedBuilder(
            animation: _barFill,
            builder: (_, __) {
              final fill = _barFill.value.clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_kTeal, _kGold]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: _kGold.withOpacity(0.45),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Level-up banner ───────────────────────────────────────────────────────

  Widget _buildLevelUpBanner() {
    final lvl = levelForXp(widget.totalXpAfter);
    return AnimatedBuilder(
      animation: _levelUpCtrl,
      builder: (_, child) => Opacity(
        opacity: _lvlFade.value,
        child: Transform.scale(scale: _lvlScale.value, child: child),
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            _kGold.withOpacity(0.18),
            _kGoldDeep.withOpacity(0.08),
          ]),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _kGold.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            const Text('✦',
                style: TextStyle(color: _kGold, fontSize: 18)),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(
                  'ارتقيتَ للمستوى ${lvl.level}!',
                  style: GoogleFonts.tajawal(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kGold,
                      letterSpacing: -0.2),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  lvl.titleAr,
                  style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: _kGoldMid.withOpacity(0.8),
                      fontWeight: FontWeight.w600),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Text('✦',
                style: TextStyle(color: _kGold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  // ── Continue button ────────────────────────────────────────────────────────

  Widget _buildButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGoldDeep, _kGold, _kGoldDeep],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _kGold.withOpacity(0.38),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Center(
          child: Text(
            'متابعة',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1200),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Islamic confetti ─────────────────────────────────────────────────────────

enum _Shape { star4, circle, diamond, crescent }

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final _Shape shape;
  final double rotSpeed;

  static const _palette = [
    _kGold,
    _kGoldMid,
    _kTeal,
    Color(0xFFFB923C),
    Color(0xFFA78BFA),
    Color(0xFF34D399),
    Color(0xFFF9A8D4),
    Color(0xFFE5C07B),
  ];

  _Particle(math.Random rng, int index, int total)
      : angle    = (index / total) * math.pi * 2 + rng.nextDouble() * 0.55,
        speed    = 65 + rng.nextDouble() * 90,
        size     = 4.0 + rng.nextDouble() * 5.5,
        color    = _palette[rng.nextInt(_palette.length)],
        shape    = _Shape.values[rng.nextInt(_Shape.values.length)],
        rotSpeed = (rng.nextDouble() - 0.5) * 2.5;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Offset origin;

  const _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final t = Curves.easeOut.transform(progress);

    for (final p in particles) {
      final dist = t * p.speed;
      final dx   = math.cos(p.angle) * dist;
      final dy   = math.sin(p.angle) * dist - t * 30;

      final opacity = (progress < 0.15
              ? progress / 0.15
              : 1.0 - ((progress - 0.15) / 0.85))
          .clamp(0.0, 1.0);

      if (opacity < 0.02) continue;

      final pos   = Offset(origin.dx + dx, origin.dy + dy);
      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(progress * p.rotSpeed * math.pi * 2);

      switch (p.shape) {
        case _Shape.star4:
          _star4(canvas, p.size, paint);
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.65, paint);
        case _Shape.diamond:
          _diamond(canvas, p.size, paint);
        case _Shape.crescent:
          _crescent(canvas, p.size, paint);
      }

      canvas.restore();
    }
  }

  void _star4(Canvas canvas, double r, Paint paint) {
    final path = Path();
    const n = 4;
    for (int i = 0; i < n * 2; i++) {
      final a  = (i * math.pi / n) - math.pi / 2;
      final ir = i.isEven ? r : r * 0.38;
      final x  = ir * math.cos(a);
      final y  = ir * math.sin(a);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _diamond(Canvas canvas, double r, Paint paint) {
    canvas.drawPath(
        Path()
          ..moveTo(0, -r)
          ..lineTo(r * 0.55, 0)
          ..lineTo(0, r)
          ..lineTo(-r * 0.55, 0)
          ..close(),
        paint);
  }

  void _crescent(Canvas canvas, double r, Paint paint) {
    canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.75),
        -math.pi * 0.1,
        math.pi * 1.2,
        true,
        paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── helpers ───────────────────────────────────────────────────────────────────

String _dayLabel(int n) {
  if (n == 1) return 'يوم واحد';
  if (n == 2) return 'يومان';
  if (n >= 3 && n <= 10) return 'أيام متواصلة';
  return 'يومًا متواصلاً';
}

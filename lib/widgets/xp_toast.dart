import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

const _kToastGold = Color(0xFFFCD34D);
const _kToastGoldDeep = Color(0xFFD97706);
const _kToastIce = Color(0xFF7DD3FC);
const _kToastIceDeep = Color(0xFF0EA5E9);

/// يعرض شارة عائمة متحركة عند كسب نقاط الخبرة أو إنفاقها، دون حجب الشاشة
/// أو انتظار تفاعل المستخدم — تُزال نفسها تلقائيًا بعد انتهاء حركتها.
void showXpToast(
  BuildContext context, {
  required int amount,
  bool isGain = true,
  String? caption,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _XpToast(
      amount: amount,
      isGain: isGain,
      caption: caption,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _XpToast extends StatefulWidget {
  final int amount;
  final bool isGain;
  final String? caption;
  final VoidCallback onDone;

  const _XpToast({
    required this.amount,
    required this.isGain,
    required this.caption,
    required this.onDone,
  });

  @override
  State<_XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<_XpToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85).chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
    ]).animate(_ctrl);

    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 74),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 14),
    ]).animate(_ctrl);

    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.35), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 68),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.25))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGain = widget.isGain;
    final glow = isGain ? _kToastGold : _kToastIce;
    final deep = isGain ? _kToastGoldDeep : _kToastIceDeep;
    final icon = isGain ? Icons.bolt_rounded : Icons.ac_unit_rounded;
    final sign = isGain ? '+' : '-';

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fade.value.clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: _slide.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Center(child: _buildBadge(glow, deep, icon, sign)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(Color glow, Color deep, IconData icon, String sign) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [deep, glow],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sign${widget.amount} XP',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.0,
                  ),
                ),
                if (widget.caption != null)
                  Text(
                    widget.caption!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.2,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

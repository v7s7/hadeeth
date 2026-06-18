import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_characters.dart';
import '../../models/user_gender.dart';
import '../../services/local_storage_service.dart';
import '../../services/session_service.dart';
import '../../widgets/character_avatar.dart';

/// شاشة الكشف عن الشخصية — تظهر بعد اختيار الجنس مباشرة.
///
/// تُعرض شخصية المستخدم بأنيميشن تكبير، مع نص ترحيب مُراعٍ للجنس.
/// يضغط المستخدم على "ابدأ رحلتك" لإتمام الترحيب والانتقال للرئيسية.
class CharacterRevealScreen extends StatefulWidget {
  const CharacterRevealScreen({super.key});

  @override
  State<CharacterRevealScreen> createState() =>
      _CharacterRevealScreenState();
}

class _CharacterRevealScreenState extends State<CharacterRevealScreen>
    with SingleTickerProviderStateMixin {
  UserGender _gender = UserGender.male; // overwritten in didChangeDependencies
  CharacterOption? _character;
  String? _preferredName;
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _textSlide;

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.65, curve: Curves.elasticOut)),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.1, 0.55, curve: Curves.easeIn)),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      final extra = GoRouterState.of(context).extra;
      _gender = (extra is UserGender) ? extra : UserGender.male;
      // تحميل الشخصية المختارة من التخزين المحلي
      _loadCharacter();
      // تأخير صغير ليشعر المستخدم بالانتقال
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  Future<void> _loadCharacter() async {
    final id = LocalStorageService.cachedCharacterId ??
        await LocalStorageService().loadCharacterId();
    final name = LocalStorageService.cachedPreferredName ??
        await LocalStorageService().loadPreferredName();
    final char = AppCharacters.findById(id) ?? AppCharacters.defaultFor(_gender);
    if (mounted) {
      setState(() {
        _character = char;
        _preferredName = name;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final session = context.read<SessionService>();
    await LocalStorageService().markWelcomeComplete();
    final characterId =
        _character?.id ?? AppCharacters.defaultFor(_gender).id;
    await session.savePersonalization(
          gender: _gender,
          characterId: characterId,
          preferredName: _preferredName ?? '',
          completedWelcome: true,
        );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(_gender.primaryColorValue);
    final secondary = Color(_gender.secondaryColorValue);
    final glow = Color(_gender.glowColorValue);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final characterSize = (screenHeight * 0.24).clamp(140.0, 200.0).toDouble();
    final textGap = (screenHeight * 0.045).clamp(20.0, 40.0).toDouble();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withOpacity(0.85),
              const Color(0xFF0D1117),
              const Color(0xFF0D1117),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
              const SizedBox(height: 12),
              const _WelcomeStepIndicator(currentStep: 2),
              const Spacer(),
              // ── Animated character ──────────────────────────────────────────
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fade,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow backdrop
                    Container(
                      width: characterSize,
                      height: characterSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glow.withOpacity(0.4),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    if (_character != null)
                      Semantics(
                        label: 'شخصيتك المختارة: ${_character!.labelAr}',
                        image: true,
                        child: CharacterAvatar(
                          character: _character!,
                          height: characterSize,
                        ),
                      )
                    else
                      SizedBox(height: characterSize),
                  ],
                ),
              ),
              SizedBox(height: textGap),
              // ── Welcome text ────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      _preferredName == null || _preferredName!.trim().isEmpty
                          ? _gender.welcomeText
                          : 'مرحبًا، ${_preferredName!.trim()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _character == null
                          ? 'اختر الشخصية التي تحبها وابدأ رحلتك'
                          : 'رفيقك في القراءة والتذكير اليومي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 28),
                    // Character badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: secondary.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: secondary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _character?.labelAr ?? _gender.studentTitle,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // ── Start button ────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _fade,
                builder: (context, child) {
                  return FadeTransition(opacity: _fade, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: _StartButton(
                    gender: _gender,
                    onTap: _finish,
                  ),
                ),
              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _WelcomeStepIndicator extends StatelessWidget {
  final int currentStep;

  const _WelcomeStepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final step = index + 1;
        final active = currentStep == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 34 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _StartButton extends StatelessWidget {
  final UserGender gender;
  final VoidCallback onTap;

  const _StartButton({required this.gender, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = Color(gender.secondaryColorValue);
    final glow = Color(gender.glowColorValue);

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(gender.primaryColorValue), secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              'ابدأ رحلتك ✨',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

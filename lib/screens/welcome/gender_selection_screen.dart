import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_characters.dart';
import '../../models/user_gender.dart';
import '../../services/local_storage_service.dart';
import '../../services/progress_service.dart';

/// شاشة اختيار الجنس والشخصية — أول شاشة يراها المستخدم الجديد.
///
/// بطاقتان (ذكر / أنثى) تعرضان معاينة PNG للشخصية.
/// عند اختيار الجنس تظهر 3 خيارات للشخصية داخل البطاقة المختارة.
class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen>
    with TickerProviderStateMixin {
  UserGender? _selectedGender;
  CharacterOption? _selectedCharacter;
  bool _confirming = false;

  late AnimationController _maleCtrl;
  late AnimationController _femaleCtrl;

  @override
  void initState() {
    super.initState();
    _maleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _femaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(const Duration(milliseconds: 100),
        () { if (mounted) _maleCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 250),
        () { if (mounted) _femaleCtrl.forward(); });
  }

  @override
  void dispose() {
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    super.dispose();
  }

  void _selectGender(UserGender gender) {
    if (_selectedGender == gender) return;
    setState(() {
      _selectedGender = gender;
      _selectedCharacter = AppCharacters.defaultFor(gender);
    });
  }

  void _selectCharacter(CharacterOption character) {
    setState(() => _selectedCharacter = character);
  }

  Future<void> _confirm() async {
    final gender = _selectedGender;
    final character = _selectedCharacter;
    if (gender == null || character == null || _confirming) return;
    setState(() => _confirming = true);

    await LocalStorageService().saveGender(gender);
    await LocalStorageService().saveCharacterId(character.id);

    if (!mounted) return;
    context.pushReplacement('/welcome/reveal', extra: _selectedGender);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 36),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(builder: (ctx) {
                  final level = ctx.watch<ProgressService>().currentLevel.level;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _GenderCard(
                          gender: UserGender.male,
                          selected: _selectedGender == UserGender.male,
                          selectedCharacter: _selectedGender == UserGender.male
                              ? _selectedCharacter
                              : null,
                          currentLevel: level,
                          entranceAnim: _maleCtrl,
                          onGenderTap: () => _selectGender(UserGender.male),
                          onCharacterTap: _selectCharacter,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _GenderCard(
                          gender: UserGender.female,
                          selected: _selectedGender == UserGender.female,
                          selectedCharacter: _selectedGender == UserGender.female
                              ? _selectedCharacter
                              : null,
                          currentLevel: level,
                          entranceAnim: _femaleCtrl,
                          onGenderTap: () => _selectGender(UserGender.female),
                          onCharacterTap: _selectCharacter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),
            _buildContinueButton(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'مرحبًا بك',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Text(
          'اختر شخصيتك لتبدأ رحلتك',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 15,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isReady = _selectedGender != null && _selectedCharacter != null;
    final color = isReady
        ? Color(_selectedGender!.secondaryColorValue)
        : Colors.white.withOpacity(0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: Color(_selectedGender!.glowColorValue)
                        .withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isReady ? _confirm : null,
            child: Center(
              child: _confirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'ابدأ',
                      style: TextStyle(
                        color: isReady
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── بطاقة الجنس ──────────────────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final UserGender gender;
  final bool selected;
  final CharacterOption? selectedCharacter;
  final int currentLevel;
  final AnimationController entranceAnim;
  final VoidCallback onGenderTap;
  final ValueChanged<CharacterOption> onCharacterTap;

  const _GenderCard({
    required this.gender,
    required this.selected,
    required this.selectedCharacter,
    required this.currentLevel,
    required this.entranceAnim,
    required this.onGenderTap,
    required this.onCharacterTap,
  });

  Color get _primary => Color(gender.primaryColorValue);
  Color get _secondary => Color(gender.secondaryColorValue);
  Color get _glow => Color(gender.glowColorValue);

  CharacterOption get _representative => AppCharacters.defaultFor(gender);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entranceAnim,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: entranceAnim,
          curve: Curves.easeOutBack,
        ).value;
        return Transform.scale(
          scale: t,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: onGenderTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? _primary.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? _secondary.withOpacity(0.65)
                  : Colors.white.withOpacity(0.1),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _glow.withOpacity(0.22),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── صورة الشخصية الرئيسية ─────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: selected && selectedCharacter != null
                      ? Image.asset(
                          selectedCharacter!.assetPath,
                          height: 110,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          _representative.assetPath,
                          height: 110,
                          fit: BoxFit.contain,
                          color: selected
                              ? null
                              : Colors.white.withOpacity(0.4),
                          colorBlendMode: selected
                              ? null
                              : BlendMode.modulate,
                        ),
                ),
                const SizedBox(height: 12),

                // ── الاسم ─────────────────────────────────────────────────
                Text(
                  gender == UserGender.male ? 'ذكر' : 'أنثى',
                  style: TextStyle(
                    color: selected ? _secondary : Colors.white.withOpacity(0.7),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gender == UserGender.male ? 'طالبٌ للعلم' : 'طالبةٌ للعلم',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                  ),
                  textDirection: TextDirection.rtl,
                ),

                // ── منتقي الشخصية — يظهر عند التحديد ────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  child: selected
                      ? _CharacterPicker(
                          characters: AppCharacters.forGender(gender),
                          selected: selectedCharacter,
                          currentLevel: currentLevel,
                          accentColor: _secondary,
                          glowColor: _glow,
                          onTap: onCharacterTap,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── منتقي الشخصيات الثلاث ────────────────────────────────────────────────────

class _CharacterPicker extends StatelessWidget {
  final List<CharacterOption> characters;
  final CharacterOption? selected;
  final int currentLevel;
  final Color accentColor;
  final Color glowColor;
  final ValueChanged<CharacterOption> onTap;

  const _CharacterPicker({
    required this.characters,
    required this.selected,
    required this.currentLevel,
    required this.accentColor,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Container(
            height: 1,
            color: accentColor.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: characters.map((char) {
              final isUnlocked = char.isUnlockedAt(currentLevel);
              final isSelected = selected?.id == char.id && isUnlocked;
              return GestureDetector(
                onTap: isUnlocked ? () => onTap(char) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: glowColor.withOpacity(0.35), blurRadius: 10)]
                        : [],
                    color: isSelected
                        ? accentColor.withOpacity(0.12)
                        : Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Character image (dimmed if locked)
                      ColorFiltered(
                        colorFilter: isUnlocked
                            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                            : const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      0.4, 0,
                              ]),
                        child: Image.asset(
                          char.assetPath,
                          height: 58,
                          width: 46,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Lock overlay
                      if (!isUnlocked)
                        Container(
                          width: 46,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(height: 2),
                              Text(
                                'L${char.unlockLevel}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (selected != null && selected!.isUnlockedAt(currentLevel))
            Text(
              selected!.labelAr,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'شخصيات تُفتح مع التقدم',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

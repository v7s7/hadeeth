import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_characters.dart';
import '../../models/user_gender.dart';
import '../../services/local_storage_service.dart';
import '../../services/session_service.dart';
import '../../widgets/character_avatar.dart';

/// شاشة اختيار الجنس والشخصية — أول شاشة يراها المستخدم الجديد.
class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen>
    with TickerProviderStateMixin {
  UserGender? _selectedGender;
  CharacterOption? _selectedCharacter;
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  final _nameFocusNode = FocusNode();
  bool _confirming = false;

  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionService>();
    _nameController.text =
        session.preferredName ?? LocalStorageService.cachedPreferredName ?? '';
    _selectedGender = session.gender ?? LocalStorageService.cachedGender;
    _selectedCharacter = AppCharacters.findById(
          session.characterId ?? LocalStorageService.cachedCharacterId,
        ) ??
        (_selectedGender != null
            ? AppCharacters.defaultFor(_selectedGender!)
            : null);

    _nameFocusNode.addListener(_scrollToButtonWhenKeyboardOpens);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_scrollToButtonWhenKeyboardOpens);
    _nameController.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _scrollToButtonWhenKeyboardOpens() {
    if (!_nameFocusNode.hasFocus) return;
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
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
    final session = context.read<SessionService>();
    setState(() => _confirming = true);
    try {
      await LocalStorageService().saveGender(gender);
      await LocalStorageService().saveCharacterId(character.id);
      await LocalStorageService().savePreferredName(_nameController.text);
      await session.savePersonalization(
        gender: gender,
        characterId: character.id,
        preferredName: _nameController.text,
        completedWelcome: false,
      );
      if (!mounted) return;
      context.pushReplacement('/welcome/reveal', extra: _selectedGender);
    } catch (_) {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _selectedGender != null && _selectedCharacter != null;
    final accentColor = _selectedGender != null
        ? Color(_selectedGender!.secondaryColorValue)
        : Colors.white.withOpacity(0.35);
    final glowColor = _selectedGender != null
        ? Color(_selectedGender!.glowColorValue)
        : Colors.transparent;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  const _WelcomeStepIndicator(currentStep: 1),
                  const SizedBox(height: 18),

                  // ── Title ──────────────────────────────────────────────────
                  const Text(
                    'مرحبًا بك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اختر شخصيتك لتبدأ رحلتك',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Gender toggle ──────────────────────────────────────────
                  _GenderToggle(
                    selectedGender: _selectedGender,
                    onSelect: _selectGender,
                  ),
                  const SizedBox(height: 28),

                  // ── Big character preview ─────────────────────────────────
                  _CharacterPreview(
                    gender: _selectedGender,
                    character: _selectedCharacter,
                  ),
                  const SizedBox(height: 18),

                  // ── Character picker row (no boxes) ───────────────────────
                  _CharacterPickerRow(
                    gender: _selectedGender,
                    selected: _selectedCharacter,
                    accentColor: accentColor,
                    glowColor: glowColor,
                    onTap: _selectCharacter,
                  ),
                  const SizedBox(height: 24),

                  // ── Name field ─────────────────────────────────────────────
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    scrollPadding: const EdgeInsets.only(bottom: 140),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'اسمك',
                      hintText: 'كيف تحب أن نخاطبك؟',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.75)),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.35)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.12)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Continue button ────────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isReady
                          ? accentColor
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isReady
                          ? [
                              BoxShadow(
                                color: glowColor.withOpacity(0.4),
                                blurRadius: 22,
                                offset: const Offset(0, 7),
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
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

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

// ── Gender Toggle (segmented pill) ───────────────────────────────────────────

class _GenderToggle extends StatelessWidget {
  final UserGender? selectedGender;
  final ValueChanged<UserGender> onSelect;

  const _GenderToggle({
    required this.selectedGender,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _GenderPill(
            gender: UserGender.male,
            label: 'ذكر',
            selected: selectedGender == UserGender.male,
            onTap: () => onSelect(UserGender.male),
          ),
          _GenderPill(
            gender: UserGender.female,
            label: 'أنثى',
            selected: selectedGender == UserGender.female,
            onTap: () => onSelect(UserGender.female),
          ),
        ],
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  final UserGender gender;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderPill({
    required this.gender,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Color(gender.primaryColorValue);
    final glow = Color(gender.glowColorValue);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.9) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [BoxShadow(color: glow.withOpacity(0.35), blurRadius: 12)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                fontSize: 15,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Character Preview (big, animated) ────────────────────────────────────────

class _CharacterPreview extends StatelessWidget {
  final UserGender? gender;
  final CharacterOption? character;

  const _CharacterPreview({
    required this.gender,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final previewHeight =
        (screenHeight * 0.22).clamp(130.0, 180.0).toDouble();
    final glowColor = gender != null
        ? Color(gender!.glowColorValue)
        : Colors.transparent;

    return SizedBox(
      height: previewHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          );
        },
        child: character != null
            ? _CharacterWithGlow(
                key: ValueKey(character!.id),
                character: character!,
                height: previewHeight,
                glowColor: glowColor,
              )
            : _PlaceholderCharacters(
                key: const ValueKey('placeholder'),
                height: previewHeight,
              ),
      ),
    );
  }
}

class _CharacterWithGlow extends StatelessWidget {
  final CharacterOption character;
  final double height;
  final Color glowColor;

  const _CharacterWithGlow({
    super.key,
    required this.character,
    required this.height,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft diffused glow — no visible border ring
        Container(
          width: height * 0.65,
          height: height * 0.65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.38),
                blurRadius: 70,
                spreadRadius: 12,
              ),
            ],
          ),
        ),
        CharacterAvatar(character: character, height: height),
      ],
    );
  }
}

class _PlaceholderCharacters extends StatelessWidget {
  final double height;

  const _PlaceholderCharacters({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.22,
          child: CharacterAvatar(
            character: AppCharacters.defaultFor(UserGender.female),
            height: height * 0.8,
          ),
        ),
        const SizedBox(width: 28),
        Opacity(
          opacity: 0.22,
          child: CharacterAvatar(
            character: AppCharacters.defaultFor(UserGender.male),
            height: height * 0.8,
          ),
        ),
      ],
    );
  }
}

// ── Character Picker Row (no box borders) ─────────────────────────────────────

class _CharacterPickerRow extends StatelessWidget {
  final UserGender? gender;
  final CharacterOption? selected;
  final Color accentColor;
  final Color glowColor;
  final ValueChanged<CharacterOption> onTap;

  const _CharacterPickerRow({
    required this.gender,
    required this.selected,
    required this.accentColor,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Reserve space before gender is picked so layout stays stable
    if (gender == null) {
      return const SizedBox(height: 88);
    }

    final characters = AppCharacters.forGender(gender!);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: characters.map((char) {
            final isSelected = selected?.id == char.id;
            return GestureDetector(
              onTap: () => onTap(char),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    // Circle background glow — NO rectangular box
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? accentColor.withOpacity(0.13)
                            : Colors.transparent,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: glowColor.withOpacity(0.3),
                                  blurRadius: 20,
                                ),
                              ]
                            : [],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: AnimatedScale(
                        scale: isSelected ? 1.1 : 0.88,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: CharacterAvatar(
                          character: char,
                          height: 60,
                          opacity: isSelected ? 1.0 : 0.42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Animated pill dot indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isSelected ? 20 : 5,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Character name label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selected != null
              ? Text(
                  key: ValueKey(selected!.id),
                  selected!.labelAr,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const SizedBox(key: ValueKey('_empty'), height: 16),
        ),
      ],
    );
  }
}

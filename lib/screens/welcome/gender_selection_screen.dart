import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_characters.dart';
import '../../models/user_gender.dart';
import '../../services/local_storage_service.dart';
import '../../services/session_service.dart';
import '../../widgets/character_avatar.dart';

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
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  final _nameFocusNode = FocusNode();
  bool _confirming = false;

  late AnimationController _maleCtrl;
  late AnimationController _femaleCtrl;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionService>();
    final sessionName = session.preferredName;
    final localName = LocalStorageService.cachedPreferredName;
    _nameController.text = sessionName ?? localName ?? '';
    _selectedGender = session.gender ?? LocalStorageService.cachedGender;
    _selectedCharacter = AppCharacters.findById(
          session.characterId ?? LocalStorageService.cachedCharacterId,
        ) ??
        (_selectedGender != null
            ? AppCharacters.defaultFor(_selectedGender!)
            : null);
    _nameFocusNode.addListener(_scrollToButtonWhenKeyboardOpens);
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
    _nameFocusNode.removeListener(_scrollToButtonWhenKeyboardOpens);
    _nameController.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            final availableWidth = constraints.maxWidth;
            final contentWidth = availableWidth > 900 ? 900.0 : availableWidth;
            final horizontalPadding = availableWidth < 380 ? 14.0 : 20.0;
            final cardHeight = (constraints.maxHeight - 270 - bottomInset)
                .clamp(300.0, availableWidth >= 700 ? 500.0 : 430.0)
                .toDouble();

            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                    const SizedBox(height: 32),
                    const _WelcomeStepIndicator(currentStep: 1),
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: cardHeight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _GenderCard(
                                gender: UserGender.male,
                                selected: _selectedGender == UserGender.male,
                                selectedCharacter:
                                    _selectedGender == UserGender.male
                                        ? _selectedCharacter
                                        : null,
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
                                selectedCharacter:
                                    _selectedGender == UserGender.female
                                        ? _selectedCharacter
                                        : null,
                                entranceAnim: _femaleCtrl,
                                onGenderTap: () => _selectGender(UserGender.female),
                                onCharacterTap: _selectCharacter,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNameField(),
                    const SizedBox(height: 12),
                    _buildContinueButton(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        scrollPadding: const EdgeInsets.only(bottom: 140),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'اسمك',
          hintText: 'كيف تحب أن نخاطبك؟',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white70),
          ),
        ),
      ),
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

// ── بطاقة الجنس ──────────────────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final UserGender gender;
  final bool selected;
  final CharacterOption? selectedCharacter;
  final AnimationController entranceAnim;
  final VoidCallback onGenderTap;
  final ValueChanged<CharacterOption> onCharacterTap;

  const _GenderCard({
    required this.gender,
    required this.selected,
    required this.selectedCharacter,
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
          child: Opacity(opacity: t.clamp(0.0, 1.0).toDouble(), child: child),
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
                      ? CharacterAvatar(
                          character: selectedCharacter!,
                          height: 110,
                        )
                      : CharacterAvatar(
                          character: _representative,
                          height: 110,
                          opacity: selected ? 1 : 0.4,
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
  final Color accentColor;
  final Color glowColor;
  final ValueChanged<CharacterOption> onTap;

  const _CharacterPicker({
    required this.characters,
    required this.selected,
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
              final isSelected = selected?.id == char.id;
              return GestureDetector(
                onTap: () => onTap(char),
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
                      Semantics(
                        label: 'اختيار شخصية ${char.labelAr}',
                        button: true,
                        child: CharacterAvatar(
                          character: char,
                          height: 58,
                          width: 46,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (selected != null)
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
              'كل الشخصيات متاحة من البداية',
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

import 'user_gender.dart';

/// بيانات شخصية واحدة قابلة للاختيار.
class CharacterOption {
  final String id;
  final String assetPath;
  final UserGender gender;
  final String labelAr;

  /// كان يُستخدم سابقًا للفتح بالمستوى؛ الشخصيات الآن اختيارية كلها من البداية.
  final int unlockLevel;

  const CharacterOption({
    required this.id,
    required this.assetPath,
    required this.gender,
    required this.labelAr,
    this.unlockLevel = 1,
  });

  bool isUnlockedAt(int level) => true;
}

/// جميع الشخصيات المتاحة في التطبيق — ثلاثة للذكور وثلاثة للإناث.
class AppCharacters {
  // ── ذكور ──────────────────────────────────────────────────────────────────

  // Available from the start
  static const male1 = CharacterOption(
    id: 'male_ghutra_blue',
    assetPath: 'assets/images/character/male_ghutra_blue.png',
    gender: UserGender.male,
    labelAr: 'الغترة الزرقاء',
    unlockLevel: 1,
  );

  // Available from the start
  static const male2 = CharacterOption(
    id: 'male_bisht_gold',
    assetPath: 'assets/images/character/male_bisht_gold.png',
    gender: UserGender.male,
    labelAr: 'البشت الذهبي',
    unlockLevel: 1,
  );

  // Available from the start
  static const male3 = CharacterOption(
    id: 'male_shmagh_red',
    assetPath: 'assets/images/character/male_shmagh_red.png',
    gender: UserGender.male,
    labelAr: 'الشماغ الأحمر',
    unlockLevel: 1,
  );

  // ── إناث ──────────────────────────────────────────────────────────────────

  // Available from the start
  static const female1 = CharacterOption(
    id: 'female_hijab_pink',
    assetPath: 'assets/images/character/female_hijab_pink.png',
    gender: UserGender.female,
    labelAr: 'الحجاب الوردي',
    unlockLevel: 1,
  );

  // Available from the start
  static const female2 = CharacterOption(
    id: 'female_niqab',
    assetPath: 'assets/images/character/female_niqab.png',
    gender: UserGender.female,
    labelAr: 'النقاب',
    unlockLevel: 1,
  );

  // Available from the start
  static const female3 = CharacterOption(
    id: 'female_hijab_teal',
    assetPath: 'assets/images/character/female_hijab_teal.png',
    gender: UserGender.female,
    labelAr: 'الزي المطرز',
    unlockLevel: 1,
  );

  // ── قوائم ─────────────────────────────────────────────────────────────────

  static const List<CharacterOption> males = [male1, male2, male3];
  static const List<CharacterOption> females = [female1, female2, female3];

  static List<CharacterOption> forGender(UserGender gender) =>
      gender == UserGender.male ? males : females;

  /// الشخصية الافتراضية لكل جنس.
  static CharacterOption defaultFor(UserGender gender) =>
      gender == UserGender.male ? male1 : female1;

  /// جميع الشخصيات متاحة للاختيار بغض النظر عن المستوى.
  static List<CharacterOption> unlockedFor(UserGender gender, int level) =>
      forGender(gender).where((c) => c.isUnlockedAt(level)).toList();

  /// لم تعد الشخصيات مرتبطة بالمستوى.
  static List<CharacterOption> newlyUnlocked(
          UserGender gender, int fromLevel, int toLevel) =>
      const [];

  /// البحث عن شخصية بمعرّفها — null إن لم توجد.
  static CharacterOption? findById(String? id) {
    if (id == null) return null;
    try {
      return [...males, ...females].firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

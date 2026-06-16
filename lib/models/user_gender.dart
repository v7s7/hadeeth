/// جنس المستخدم — يؤثر على الشخصية المعروضة وتصريف الأفعال في العربية.
enum UserGender {
  male,
  female;

  // ── Labels ────────────────────────────────────────────────────────────────

  String get labelAr => this == male ? 'ذكر' : 'أنثى';

  // ── Gender-aware Arabic text ──────────────────────────────────────────────

  /// أهلاً بكَ / أهلاً بكِ
  String get welcomeText => this == male ? 'أهلاً بكَ' : 'أهلاً بكِ';

  /// أنتَ / أنتِ
  String get pronoun => this == male ? 'أنتَ' : 'أنتِ';

  /// طالبٌ / طالبةٌ
  String get studentTitle => this == male ? 'طالبٌ' : 'طالبةٌ';

  /// حافظٌ / حافظةٌ
  String get scholarTitle => this == male ? 'حافظٌ' : 'حافظةٌ';

  /// نشيطٌ / نشيطةٌ
  String get activeAdjective => this == male ? 'نشيطٌ' : 'نشيطةٌ';

  /// ابدأ / ابدئي
  String get startVerb => this == male ? 'ابدأ' : 'ابدئي';

  /// واصل / واصلي
  String get continueVerb => this == male ? 'واصل' : 'واصلي';

  /// رائع! / رائعة!
  String get amazingExclaim => this == male ? 'رائع!' : 'رائعة!';

  /// "أكملتَ" / "أكملتِ"
  String conjugatePast(String verbStem) =>
      this == male ? '${verbStem}تَ' : '${verbStem}تِ';

  // ── Colors ────────────────────────────────────────────────────────────────

  /// اللون الرئيسي للشخصية (hex value as int)
  int get primaryColorValue =>
      this == male ? 0xFF1F6F5C : 0xFF6D28D9;

  int get secondaryColorValue =>
      this == male ? 0xFF2AA87B : 0xFFA78BFA;

  int get glowColorValue =>
      this == male ? 0xFF38D89C : 0xFFD8B4FE;

  // ── Persistence ───────────────────────────────────────────────────────────

  static UserGender fromString(String? value) {
    return values.firstWhere(
      (g) => g.name == value,
      orElse: () => male,
    );
  }
}

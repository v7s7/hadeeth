/// قواعد التحقق المشتركة بين نماذج تسجيل الدخول وإنشاء الحساب واستعادة
/// كلمة المرور — موحّدة هنا لتجنّب تكرارها بقواعد مختلفة في كل شاشة.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'أدخل البريد الإلكتروني';
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
    if (value.length < minLength) return 'كلمة المرور $minLength أحرف على الأقل';
    return null;
  }

  /// قوة كلمة المرور من 0 (فارغة) إلى 4 (قوية جدًا) — لعرض مؤشر مرئي فقط،
  /// لا تُستخدم كقاعدة رفض.
  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score.clamp(0, 4);
  }
}

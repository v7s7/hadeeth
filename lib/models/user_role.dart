/// دور المستخدم في النظام.
enum UserRole {
  user,

  /// مشرف محتوى: يستطيع إرسال أحاديث وتصنيفات للمراجعة، لا ينشر مباشرة.
  admin,

  /// مشرف عام: صلاحيات كاملة، يراجع ويقرّ مقدّمات المشرفين.
  superAdmin;

  String get labelAr {
    switch (this) {
      case UserRole.user:
        return 'مستخدم';
      case UserRole.admin:
        return 'مشرف محتوى';
      case UserRole.superAdmin:
        return 'مشرف عام';
    }
  }

  static UserRole fromName(String? name) {
    return UserRole.values.firstWhere(
      (value) => value.name == name,
      orElse: () => UserRole.user,
    );
  }
}

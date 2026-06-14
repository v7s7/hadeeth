/// دور المستخدم في النظام.
enum UserRole {
  user,
  superAdmin;

  String get labelAr {
    switch (this) {
      case UserRole.user:
        return 'مستخدم';
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

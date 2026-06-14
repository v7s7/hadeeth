import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// ملف المستخدم المخزَّن في Firestore (users/{uid})، يحدد دوره وحالة حسابه.
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isDisabled;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isDisabled,
    required this.createdAt,
  });

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    bool? isDisabled,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isDisabled': isDisabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: UserRole.fromName(map['role'] as String?),
      isDisabled: map['isDisabled'] as bool? ?? false,
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : DateTime.now(),
    );
  }
}

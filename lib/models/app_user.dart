import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_gender.dart';
import 'user_role.dart';

/// ملف المستخدم المخزَّن في Firestore (users/{uid})، يحدد دوره وحالة حسابه.
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isDisabled;
  final DateTime createdAt;

  /// جنس المستخدم لتخصيص الشخصية والنصوص العربية.
  final UserGender? gender;
  final String? characterId;
  final String? activeAccessoryId;
  final bool completedOnboarding;
  final bool completedWelcome;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isDisabled,
    required this.createdAt,
    this.gender,
    this.characterId,
    this.activeAccessoryId,
    this.completedOnboarding = false,
    this.completedWelcome = false,
  });

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    bool? isDisabled,
    UserGender? gender,
    String? characterId,
    String? activeAccessoryId,
    bool? completedOnboarding,
    bool? completedWelcome,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt,
      gender: gender ?? this.gender,
      characterId: characterId ?? this.characterId,
      activeAccessoryId: activeAccessoryId ?? this.activeAccessoryId,
      completedOnboarding: completedOnboarding ?? this.completedOnboarding,
      completedWelcome: completedWelcome ?? this.completedWelcome,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isDisabled': isDisabled,
      'createdAt': Timestamp.fromDate(createdAt),
      if (gender != null) 'gender': gender!.name,
      if (characterId != null) 'characterId': characterId,
      if (activeAccessoryId != null) 'activeAccessoryId': activeAccessoryId,
      'completedOnboarding': completedOnboarding,
      'completedWelcome': completedWelcome,
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
      createdAt:
          createdAtValue is Timestamp ? createdAtValue.toDate() : DateTime.now(),
      gender: map.containsKey('gender')
          ? UserGender.fromString(map['gender'] as String?)
          : null,
      characterId: map['characterId'] as String?,
      activeAccessoryId: map['activeAccessoryId'] as String?,
      completedOnboarding: map['completedOnboarding'] as bool? ?? false,
      completedWelcome: map['completedWelcome'] as bool? ?? false,
    );
  }
}

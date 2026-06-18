import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hadeeth/models/app_user.dart';
import 'package:hadeeth/models/user_role.dart';
import 'package:hadeeth/screens/admin/admin_guard.dart';
import 'package:hadeeth/services/session_service.dart';

AppUser _userWithRole(UserRole role) => AppUser(
      id: 'u1',
      email: 'user@example.com',
      displayName: 'Test User',
      role: role,
      isDisabled: false,
      createdAt: DateTime(2026),
    );

Widget _wrap(SessionService session, Widget guard) {
  return ChangeNotifierProvider<SessionService>.value(
    value: session,
    child: MaterialApp(home: guard),
  );
}

void main() {
  group('SessionService role getters', () {
    test('guest (no profile) has no admin access', () {
      final session = SessionService();
      expect(session.isAdmin, isFalse);
      expect(session.isSuperAdmin, isFalse);
      expect(session.isAnyAdmin, isFalse);
    });

    test('plain user role has no admin access', () {
      final session = SessionService()
        ..debugSetProfile(_userWithRole(UserRole.user));
      expect(session.isAdmin, isFalse);
      expect(session.isSuperAdmin, isFalse);
      expect(session.isAnyAdmin, isFalse);
    });

    test('admin role is any-admin but not super admin', () {
      final session = SessionService()
        ..debugSetProfile(_userWithRole(UserRole.admin));
      expect(session.isAdmin, isTrue);
      expect(session.isSuperAdmin, isFalse);
      expect(session.isAnyAdmin, isTrue);
    });

    test('superAdmin role is both any-admin and super admin', () {
      final session = SessionService()
        ..debugSetProfile(_userWithRole(UserRole.superAdmin));
      expect(session.isAdmin, isFalse);
      expect(session.isSuperAdmin, isTrue);
      expect(session.isAnyAdmin, isTrue);
    });
  });

  group('AdminGuard', () {
    testWidgets('blocks guests', (tester) async {
      await tester.pumpWidget(_wrap(
        SessionService(),
        const AdminGuard(child: Text('PROTECTED')),
      ));

      expect(find.text('PROTECTED'), findsNothing);
      expect(find.text('هذه الصفحة مخصصة للمشرفين فقط'), findsOneWidget);
    });

    testWidgets('blocks plain users', (tester) async {
      final session = SessionService()
        ..debugSetProfile(_userWithRole(UserRole.user));
      await tester.pumpWidget(
          _wrap(session, const AdminGuard(child: Text('PROTECTED'))));

      expect(find.text('PROTECTED'), findsNothing);
    });

    testWidgets('allows admin and superAdmin', (tester) async {
      for (final role in [UserRole.admin, UserRole.superAdmin]) {
        final session = SessionService()..debugSetProfile(_userWithRole(role));
        await tester.pumpWidget(
            _wrap(session, const AdminGuard(child: Text('PROTECTED'))));

        expect(find.text('PROTECTED'), findsOneWidget, reason: 'role: $role');
      }
    });
  });

  group('SuperAdminGuard', () {
    testWidgets('blocks guests', (tester) async {
      await tester.pumpWidget(_wrap(
        SessionService(),
        const SuperAdminGuard(child: Text('PROTECTED')),
      ));

      expect(find.text('PROTECTED'), findsNothing);
      expect(find.text('هذه الصفحة مخصصة للمشرف العام فقط'), findsOneWidget);
    });

    testWidgets('blocks plain admin (content manager)', (tester) async {
      final session = SessionService()
        ..debugSetProfile(_userWithRole(UserRole.admin));
      await tester.pumpWidget(
          _wrap(session, const SuperAdminGuard(child: Text('PROTECTED'))));

      expect(find.text('PROTECTED'), findsNothing);
    });

    testWidgets('allows only superAdmin', (tester) async {
      final session = SessionService()
        ..debugSetProfile(_userWithRole(UserRole.superAdmin));
      await tester.pumpWidget(
          _wrap(session, const SuperAdminGuard(child: Text('PROTECTED'))));

      expect(find.text('PROTECTED'), findsOneWidget);
    });
  });
}

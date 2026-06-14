import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../widgets/empty_state.dart';

/// يحجب الوصول إلى شاشات لوحة التحكم عن أي مستخدم ليس مشرفًا عامًا.
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();

    if (!session.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'هذه الصفحة مخصصة للمشرف العام فقط',
          subtitle: 'سجّل الدخول بحساب مشرف عام للوصول إلى لوحة التحكم.',
        ),
      );
    }

    return child;
  }
}

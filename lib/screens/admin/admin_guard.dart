import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../widgets/empty_state.dart';

/// يسمح بالوصول لأي مشرف (مشرف محتوى أو مشرف عام).
class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    if (!session.isAnyAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'هذه الصفحة مخصصة للمشرفين فقط',
          subtitle: 'سجّل الدخول بحساب مشرف للوصول.',
        ),
      );
    }
    return child;
  }
}

/// يحجب الوصول لغير المشرف العام فقط.
class SuperAdminGuard extends StatelessWidget {
  final Widget child;
  const SuperAdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    if (!session.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'هذه الصفحة مخصصة للمشرف العام فقط',
          subtitle: 'تحتاج إلى صلاحيات المشرف العام للوصول.',
        ),
      );
    }
    return child;
  }
}

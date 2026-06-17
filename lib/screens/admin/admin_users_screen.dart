import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import 'admin_guard.dart';

/// شاشة إدارة المستخدمين: عرض الأدوار، منح/سحب صلاحية مشرف المحتوى، وتفعيل/تعطيل الحسابات.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot<Map<String, dynamic>>>? usersStream;
    try {
      usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    } catch (_) {
      usersStream = null;
    }

    return SuperAdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المستخدمين')),
        body: SafeArea(
          child: usersStream == null
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'تعذّر الاتصال بقاعدة البيانات',
                  subtitle: 'تأكد من إعداد Firebase لإدارة المستخدمين.',
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: usersStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const EmptyState(
                        icon: Icons.error_outline,
                        title: 'حدث خطأ أثناء تحميل المستخدمين',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const EmptyState(icon: Icons.people_outline, title: 'لا يوجد مستخدمون');
                    }

                    final users = docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserCard(user: user, isSelf: user.id == currentUid);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final bool isSelf;

  const _UserCard({required this.user, required this.isSelf});

  Future<void> _updateField(BuildContext context, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update(data);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر التحديث. تأكد من إعداد Firebase.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = user.role == UserRole.superAdmin;
    final isAdmin = user.role == UserRole.admin;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    isSuperAdmin || isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.person_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName.isNotEmpty ? user.displayName : user.email,
                        style: AppTextStyles.bodyBold,
                      ),
                      const SizedBox(height: 2),
                      Text(user.email, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (user.isDisabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('معطّل', style: AppTextStyles.badge.copyWith(color: AppColors.error)),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: Text('مشرف محتوى', style: AppTextStyles.body)),
                Switch(
                  value: isAdmin,
                  onChanged: isSelf || isSuperAdmin
                      ? null
                      : (value) => _updateField(context, {
                            'role': (value ? UserRole.admin : UserRole.user).name,
                          }),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('الحساب مفعل', style: AppTextStyles.body)),
                Switch(
                  value: !user.isDisabled,
                  onChanged: isSelf || isSuperAdmin
                      ? null
                      : (value) => _updateField(context, {'isDisabled': !value}),
                ),
              ],
            ),
            if (isSelf || isSuperAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isSelf
                      ? 'لا يمكنك تعديل دورك أو حالة حسابك الخاص.'
                      : 'لا يمكن تعديل صلاحية المشرف العام من هذه الشاشة.',
                  style: AppTextStyles.caption,
                ),
              ),

            // ── Audit button — visible for any admin/super-admin user ──
            if (!isSelf &&
                (user.role == UserRole.admin ||
                    user.role == UserRole.superAdmin)) ...[
              const Divider(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/admin/users/${user.id}/submissions',
                    extra: user.displayName.isNotEmpty
                        ? user.displayName
                        : user.email,
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('سجل مقدّماته'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

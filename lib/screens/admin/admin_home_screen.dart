import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_guard.dart';

/// الشاشة الرئيسية للوحة التحكم — تعرض محتوى مختلفًا بحسب الدور.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();

    return AdminGuard(
      child: session.isSuperAdmin
          ? const _SuperAdminDashboard()
          : const _AdminDashboard(),
    );
  }
}

// ── لوحة المشرف العام ─────────────────────────────────────────────────────────

class _SuperAdminDashboard extends StatelessWidget {
  const _SuperAdminDashboard();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final hadithsCount = context.watch<HadithRepository>().all.length;
    final categoriesCount =
        context.watch<CategoryRepository>().categories.length;

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AdminBanner(
              name: session.displayName ?? '',
              roleLabel: 'مشرف عام',
              color: AppColors.primary,
            ),

            // ── طلبات المراجعة ──────────────────────────────────────────
            const SizedBox(height: 20),
            Text('المراجعة والموافقة', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.pending_actions_rounded,
              title: 'طلبات المراجعة',
              subtitle: 'راجع وأقرّ محتوى مشرفي المحتوى',
              onTap: () => context.push('/admin/pending'),
              accent: const Color(0xFFD97706),
            ),

            // ── إدارة المحتوى ───────────────────────────────────────────
            const SizedBox(height: 20),
            Text('إدارة المحتوى', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.menu_book_outlined,
              title: 'الأحاديث',
              subtitle: '$hadithsCount حديث',
              onTap: () => context.push('/admin/hadiths'),
            ),
            _AdminTile(
              icon: Icons.category_outlined,
              title: 'التصنيفات',
              subtitle: '$categoriesCount تصنيف',
              onTap: () => context.push('/admin/categories'),
            ),

            // ── إدارة المستخدمين ────────────────────────────────────────
            const SizedBox(height: 12),
            Text('إدارة المستخدمين', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.people_outline,
              title: 'المستخدمون',
              subtitle: 'الأدوار، وتفعيل/تعطيل الحسابات',
              onTap: () => context.push('/admin/users'),
            ),

            // ── الإشعارات ───────────────────────────────────────────────
            const SizedBox(height: 12),
            Text('الإشعارات', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.campaign_rounded,
              title: 'إرسال إشعار',
              subtitle: 'أرسل إشعارًا فوريًا لجميع المستخدمين',
              onTap: () => context.push('/admin/notifications'),
              accent: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }
}

// ── لوحة مشرف المحتوى ────────────────────────────────────────────────────────

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المشرف')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AdminBanner(
              name: session.displayName ?? '',
              roleLabel: 'مشرف محتوى',
              color: const Color(0xFFD97706),
            ),

            // ── إرسال محتوى جديد ────────────────────────────────────────
            const SizedBox(height: 20),
            Text('إرسال محتوى جديد', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'يُراجَع كل محتوى من قِبَل المشرف العام قبل نشره.',
                style: AppTextStyles.caption,
              ),
            ),
            _AdminTile(
              icon: Icons.menu_book_outlined,
              title: 'إرسال حديث جديد',
              subtitle: 'أضف حديثًا كاملاً مع شرحه وأسئلته',
              onTap: () => context.push('/admin/hadiths/new'),
            ),
            _AdminTile(
              icon: Icons.category_outlined,
              title: 'إرسال تصنيف جديد',
              subtitle: 'اقترح تصنيفًا جديدًا للأحاديث',
              onTap: () => context.push('/admin/pending-category/new'),
            ),

            // ── متابعة المقدّمات ─────────────────────────────────────────
            const SizedBox(height: 12),
            Text('مقدّماتي', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.history_rounded,
              title: 'المحتوى المُرسَل',
              subtitle: 'تابع حالة أحاديثك وتصنيفاتك المُقدَّمة',
              onTap: () => context.push('/admin/submissions'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _AdminBanner extends StatelessWidget {
  final String name;
  final String roleLabel;
  final Color color;

  const _AdminBanner({
    required this.name,
    required this.roleLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child:
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحبًا، $roleLabel', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 4),
                  Text(name, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    final bg =
        accent != null ? accent!.withOpacity(0.1) : AppColors.primaryLight;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bg,
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: AppTextStyles.bodyBold),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

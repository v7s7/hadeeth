import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_guard.dart';

/// الشاشة الرئيسية للوحة التحكم.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final hadithsCount = context.watch<HadithRepository>().all.length;
    final categoriesCount =
        context.watch<CategoryRepository>().categories.length;

    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Admin banner ─────────────────────────────────────────
              Card(
                color: AppColors.primaryLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.admin_panel_settings,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحبًا، مشرف عام',
                                style: AppTextStyles.bodyBold),
                            const SizedBox(height: 4),
                            Text(session.displayName ?? '',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────
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

              // ── Users ────────────────────────────────────────────────
              const SizedBox(height: 12),
              Text('إدارة المستخدمين', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              _AdminTile(
                icon: Icons.people_outline,
                title: 'المستخدمون',
                subtitle: 'الأدوار، وتفعيل/تعطيل الحسابات',
                onTap: () => context.push('/admin/users'),
              ),

              // ── Notifications ─────────────────────────────────────────
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
    final bg = accent != null
        ? accent!.withOpacity(0.1)
        : AppColors.primaryLight;

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

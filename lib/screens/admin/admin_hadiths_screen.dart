import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hadith.dart';
import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import 'admin_guard.dart';

/// شاشة إدارة الأحاديث: عرض الكل (مع المسودات والمخفي)، تغيير الحالة، تعديل وحذف.
class AdminHadithsScreen extends StatelessWidget {
  const AdminHadithsScreen({super.key});

  Future<void> _changeStatus(BuildContext context, Hadith hadith, ContentStatus status) async {
    try {
      await context.read<HadithRepository>().setStatus(hadith.id, status);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر التحديث. تأكد من إعداد Firebase.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Hadith hadith) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحديث'),
        content: Text('هل تريد حذف "${hadith.title}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<HadithRepository>().deleteHadith(hadith.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الحديث')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الحذف. تأكد من إعداد Firebase.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hadiths = [...context.watch<HadithRepository>().all]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final categoryRepository = context.watch<CategoryRepository>();

    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الأحاديث')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/admin/hadiths/new'),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: hadiths.isEmpty
              ? const EmptyState(icon: Icons.menu_book_outlined, title: 'لا توجد أحاديث')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hadiths.length,
                  itemBuilder: (context, index) {
                    final hadith = hadiths[index];
                    final category = categoryRepository.categoryById(hadith.categoryId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          hadith.title,
                          style: AppTextStyles.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              _StatusBadge(status: hadith.status),
                              const SizedBox(width: 8),
                              if (category != null)
                                Expanded(
                                  child: Text(
                                    category.nameAr,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<ContentStatus>(
                              icon: const Icon(Icons.visibility_outlined),
                              tooltip: 'تغيير الحالة',
                              onSelected: (status) => _changeStatus(context, hadith, status),
                              itemBuilder: (context) => ContentStatus.values
                                  .map((status) => PopupMenuItem(
                                        value: status,
                                        child: Text(status.labelAr),
                                      ))
                                  .toList(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'تعديل',
                              onPressed: () => context.push('/admin/hadiths/${hadith.id}/edit'),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.error),
                              tooltip: 'حذف',
                              onPressed: () => _confirmDelete(context, hadith),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ContentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ContentStatus.published:
        color = AppColors.success;
        break;
      case ContentStatus.draft:
        color = AppColors.textMuted;
        break;
      case ContentStatus.hidden:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.labelAr, style: AppTextStyles.badge.copyWith(color: color)),
    );
  }
}

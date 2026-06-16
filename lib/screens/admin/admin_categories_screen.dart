import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/category_icons.dart';
import '../../models/hadith_category.dart';
import '../../services/category_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import 'admin_guard.dart';

/// شاشة إدارة التصنيفات: إضافة، تعديل، إخفاء/إظهار، وحذف.
class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _showForm(BuildContext context, {HadithCategory? category}) {
    return showDialog<void>(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
    );
  }

  Future<void> _toggleHidden(BuildContext context, HadithCategory category) async {
    try {
      await context.read<CategoryRepository>().setHidden(category.id, !category.isHidden);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر التحديث. تأكد من إعداد Firebase.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, HadithCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: Text('هل تريد حذف تصنيف "${category.nameAr}"؟ لا يمكن التراجع عن هذا الإجراء.'),
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
      await context.read<CategoryRepository>().deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التصنيف')),
        );
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
    final categories = context.watch<CategoryRepository>().categories;

    return SuperAdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة التصنيفات')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showForm(context),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: categories.isEmpty
              ? const EmptyState(icon: Icons.category_outlined, title: 'لا توجد تصنيفات')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(category.icon, color: AppColors.primary),
                        ),
                        title: Text(category.nameAr, style: AppTextStyles.bodyBold),
                        subtitle: category.isHidden
                            ? Text(
                                'مخفي عن المستخدمين',
                                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                category.isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              ),
                              tooltip: category.isHidden ? 'إظهار' : 'إخفاء',
                              onPressed: () => _toggleHidden(context, category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'تعديل',
                              onPressed: () => _showForm(context, category: category),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.error),
                              tooltip: 'حذف',
                              onPressed: () => _confirmDelete(context, category),
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

class _CategoryFormDialog extends StatefulWidget {
  final HadithCategory? category;

  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIconKey;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.nameAr ?? '');
    _selectedIconKey = widget.category?.iconKey ?? categoryIcons.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final repository = context.read<CategoryRepository>();
    final category = HadithCategory(
      id: widget.category?.id ?? '',
      nameAr: _nameController.text.trim(),
      iconKey: _selectedIconKey,
      isHidden: widget.category?.isHidden ?? false,
    );

    try {
      if (widget.category == null) {
        await repository.addCategory(category);
      } else {
        await repository.updateCategory(category);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الحفظ. تأكد من إعداد Firebase.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'تعديل التصنيف' : 'تصنيف جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم التصنيف'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'أدخل اسم التصنيف';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('الأيقونة', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                height: 180,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: categoryIcons.length,
                  itemBuilder: (context, index) {
                    final entry = categoryIcons.entries.elementAt(index);
                    final isSelected = entry.key == _selectedIconKey;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedIconKey = entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

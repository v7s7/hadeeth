import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/category_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_guard.dart';

/// شاشة إرسال تصنيف جديد للمراجعة — لمشرف المحتوى فقط.
class AdminPendingCategoryFormScreen extends StatefulWidget {
  const AdminPendingCategoryFormScreen({super.key});

  @override
  State<AdminPendingCategoryFormScreen> createState() =>
      _AdminPendingCategoryFormScreenState();
}

class _AdminPendingCategoryFormScreenState
    extends State<AdminPendingCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIconKey = categoryIcons.keys.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('pending_categories').add({
        'nameAr': _nameController.text.trim(),
        'iconKey': _selectedIconKey,
        'isHidden': false,
        'submittedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewStatus': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'تم إرسال التصنيف للمراجعة ✓ سيُنشر بعد موافقة المشرف العام'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الإرسال. تأكد من الاتصال.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('إرسال تصنيف للمراجعة')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Info banner ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFD97706).withOpacity(0.35)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيُراجَع التصنيف من المشرف العام قبل ظهوره في التطبيق.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Name ──────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'اسم التصنيف'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل اسم التصنيف' : null,
                ),
                const SizedBox(height: 20),

                // ── Icon picker ───────────────────────────────────
                Text('الأيقونة', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: categoryIcons.length,
                    itemBuilder: (context, index) {
                      final entry = categoryIcons.entries.elementAt(index);
                      final isSelected = entry.key == _selectedIconKey;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            setState(() => _selectedIconKey = entry.key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'جارٍ الإرسال…' : 'إرسال للمراجعة',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

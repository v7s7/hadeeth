import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hadith.dart';
import '../../models/hadith_category.dart';
import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import 'admin_guard.dart';

/// شاشة المشرف العام لمراجعة المحتوى المُرسَل وإقراره أو رفضه.
class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});

  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SuperAdminGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلبات المراجعة'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'الأحاديث'),
              Tab(text: 'التصنيفات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _PendingHadithsList(),
            _PendingCategoriesList(),
          ],
        ),
      ),
    );
  }
}

// ── قائمة الأحاديث المعلّقة ───────────────────────────────────────────────────

class _PendingHadithsList extends StatelessWidget {
  const _PendingHadithsList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_hadiths')
          .where('reviewStatus', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'لا توجد أحاديث في انتظار المراجعة',
            subtitle: 'كل الأحاديث المُرسَلة تمت مراجعتها.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _PendingHadithCard(docId: doc.id, data: data);
          },
        );
      },
    );
  }
}

// ── بطاقة حديث معلّق — تعرض مُقدِّمه وتفاصيله الكاملة قبل القرار ──────────────

class _PendingHadithCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _PendingHadithCard({required this.docId, required this.data});

  @override
  State<_PendingHadithCard> createState() => _PendingHadithCardState();
}

class _PendingHadithCardState extends State<_PendingHadithCard> {
  bool _expanded = false;

  Future<void> _approve(BuildContext context) async {
    final hadithRepo = context.read<HadithRepository>();

    final hadith = Hadith.fromMap(widget.docId, {
      ...widget.data,
      'status': ContentStatus.published.name,
    });

    try {
      // Write directly so we can attach audit metadata alongside the hadith
      await FirebaseFirestore.instance.collection('hadiths').add({
        ...hadith.toMap(),
        'submittedBy': widget.data['submittedBy'] ?? '',
        'submittedAt': widget.data['submittedAt'],
        'approvedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Mark the pending doc as approved
      await FirebaseFirestore.instance
          .collection('pending_hadiths')
          .doc(widget.docId)
          .update({
        'reviewStatus': 'approved',
        'approvedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الحديث ونشره ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الحديث'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('pending_hadiths')
          .doc(widget.docId)
          .update({
        'reviewStatus': 'rejected',
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'rejectedAt': FieldValue.serverTimestamp(),
        if (reasonCtrl.text.trim().isNotEmpty)
          'rejectionReason': reasonCtrl.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض الحديث'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.data['submittedAt'] as Timestamp?;
    final date = ts != null ? _fmt(ts.toDate()) : '…';
    final categoryRepo = context.watch<CategoryRepository>();
    final category =
        categoryRepo.categoryById(widget.data['categoryId'] as String? ?? '');
    final submittedBy = widget.data['submittedBy'] as String? ?? '';

    final benefits =
        List<String>.from(widget.data['benefits'] as List? ?? const []);
    final quizCount =
        (widget.data['quizQuestions'] as List? ?? const []).length;
    final strangeWords =
        (widget.data['strangeWords'] as List? ?? const []);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: status badge + date ───────────────────────────
            Row(
              children: [
                _StatusBadge(label: 'في انتظار المراجعة', color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7)),
                const Spacer(),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 10),

            // ── Submitter chip ────────────────────────────────────────
            if (submittedBy.isNotEmpty)
              _SubmitterChip(uid: submittedBy),

            const SizedBox(height: 8),

            // ── Title + category ──────────────────────────────────────
            Text(
              widget.data['title'] as String? ?? '',
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: 2),
            if (category != null)
              Text(category.nameAr, style: AppTextStyles.caption),
            const SizedBox(height: 6),

            // ── Hadith text preview ───────────────────────────────────
            Text(
              widget.data['hadithText'] as String? ?? '',
              style: AppTextStyles.body,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),

            // ── Expandable full details ───────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: _expanded
                  ? _FullDetails(
                      data: widget.data,
                      benefits: benefits,
                      strangeWords: strangeWords,
                      quizCount: quizCount,
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Expand toggle ─────────────────────────────────────────
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  _expanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل الكاملة',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),

            const Divider(height: 20),

            // ── Actions ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('رفض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('قبول ونشر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── شريحة اسم المُقدِّم (async lookup) ───────────────────────────────────────

class _SubmitterChip extends StatelessWidget {
  final String uid;
  const _SubmitterChip({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = data?['displayName'] as String? ?? '';
        final email = data?['email'] as String? ?? '';
        final label = name.isNotEmpty ? name : (email.isNotEmpty ? email : uid.substring(0, 8));

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'مُقدَّم من: $label',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── التفاصيل الكاملة (قسم قابل للطي) ────────────────────────────────────────

class _FullDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> benefits;
  final List strangeWords;
  final int quizCount;

  const _FullDetails({
    required this.data,
    required this.benefits,
    required this.strangeWords,
    required this.quizCount,
  });

  @override
  Widget build(BuildContext context) {
    final narrator   = data['narrator'] as String? ?? '';
    final sourceBook = data['sourceBook'] as String? ?? '';
    final sourceRef  = data['sourceReference'] as String? ?? '';
    final shortExp   = data['shortExplanation'] as String? ?? '';
    final detailExp  = data['detailedExplanation'] as String? ?? '';
    final isAbandoned = data['isAbandonedSunnah'] as bool? ?? false;
    final difficulty = data['difficultyLevel'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // ── Meta row ──────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (isAbandoned)
                _DetailChip(
                    icon: Icons.star_outline_rounded,
                    label: 'من السنن المهجورة',
                    color: AppColors.accent),
              if (difficulty.isNotEmpty)
                _DetailChip(icon: Icons.bar_chart, label: difficulty),
            ],
          ),
          const SizedBox(height: 12),

          // ── Narrator + Source ─────────────────────────────────────
          _DetailRow(label: 'الراوي', value: narrator),
          if (sourceBook.isNotEmpty)
            _DetailRow(
                label: 'المصدر',
                value: '$sourceBook — $sourceRef'),

          // ── Short explanation ─────────────────────────────────────
          if (shortExp.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SectionLabel('الشرح المختصر'),
            Text(shortExp, style: AppTextStyles.body),
          ],

          // ── Detailed explanation ──────────────────────────────────
          if (detailExp.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SectionLabel('الشرح التفصيلي'),
            Text(detailExp, style: AppTextStyles.body),
          ],

          // ── Benefits ──────────────────────────────────────────────
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SectionLabel('الفوائد (${benefits.length})'),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 5,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(b, style: AppTextStyles.body)),
                    ],
                  ),
                )),
          ],

          // ── Strange words ─────────────────────────────────────────
          if (strangeWords.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SectionLabel('كلمات غريبة (${strangeWords.length})'),
            ...strangeWords.map((w) {
              final word    = (w as Map?)?['word'] as String? ?? '';
              final meaning = (w)?['meaning'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      TextSpan(
                          text: '$word: ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      TextSpan(text: meaning),
                    ],
                  ),
                ),
              );
            }),
          ],

          // ── Quiz questions count ───────────────────────────────────
          const SizedBox(height: 10),
          _DetailChip(
            icon: Icons.quiz_outlined,
            label: 'أسئلة الاختبار: $quizCount',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── شاشة التصنيفات المعلّقة ───────────────────────────────────────────────────

class _PendingCategoriesList extends StatelessWidget {
  const _PendingCategoriesList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_categories')
          .where('reviewStatus', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'لا توجد تصنيفات في انتظار المراجعة',
            subtitle: 'كل التصنيفات المُرسَلة تمت مراجعتها.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _PendingCategoryCard(docId: doc.id, data: data);
          },
        );
      },
    );
  }
}

class _PendingCategoryCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _PendingCategoryCard({required this.docId, required this.data});

  Future<void> _approve(BuildContext context) async {
    final repo = context.read<CategoryRepository>();
    final category = HadithCategory.fromMap(docId, {
      ...data,
      'isHidden': false,
    });
    try {
      await repo.addCategory(category);
      await FirebaseFirestore.instance
          .collection('pending_categories')
          .doc(docId)
          .update({
        'reviewStatus': 'approved',
        'approvedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول التصنيف ونشره ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض التصنيف'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('رفض',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('pending_categories')
          .doc(docId)
          .update({
        'reviewStatus': 'rejected',
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'rejectedAt': FieldValue.serverTimestamp(),
        if (reasonCtrl.text.trim().isNotEmpty)
          'rejectionReason': reasonCtrl.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض التصنيف'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = data['submittedAt'] as Timestamp?;
    final date = ts != null ? _fmt(ts.toDate()) : '…';
    final submittedBy = data['submittedBy'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(label: 'في انتظار المراجعة', color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7)),
                const Spacer(),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            if (submittedBy.isNotEmpty) _SubmitterChip(uid: submittedBy),
            const SizedBox(height: 4),
            Text(
              data['nameAr'] as String? ?? '',
              style: AppTextStyles.bodyBold,
            ),
            if ((data['descriptionAr'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                data['descriptionAr'] as String,
                style: AppTextStyles.body,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('رفض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('قبول ونشر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: AppTextStyles.caption),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.sectionTitle),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _DetailChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import 'admin_guard.dart';

/// شاشة سجل مقدّمات مشرف محتوى بعينه — للمشرف العام فقط.
///
/// تعرض جميع الأحاديث والتصنيفات التي أرسلها المشرف المحدَّد
/// بكل حالاتها (معلّق / مقبول / مرفوض)، مرتّبةً بالأحدث.
class AdminUserSubmissionsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserSubmissionsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserSubmissionsScreen> createState() =>
      _AdminUserSubmissionsScreenState();
}

class _AdminUserSubmissionsScreenState
    extends State<AdminUserSubmissionsScreen>
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سجل المقدّمات'),
              Text(
                widget.userName,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
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
          children: [
            _UserHadithsTab(userId: widget.userId),
            _UserCategoriesTab(userId: widget.userId),
          ],
        ),
      ),
    );
  }
}

// ── أحاديث المشرف ─────────────────────────────────────────────────────────────

class _UserHadithsTab extends StatelessWidget {
  final String userId;
  const _UserHadithsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_hadiths')
          .where('submittedBy', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'خطأ في التحميل',
            subtitle: snapshot.error.toString(),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'لم يُرسِل هذا المشرف أي حديث',
          );
        }

        // Count by status for summary bar
        final counts = <String, int>{};
        for (final d in docs) {
          final s = (d.data() as Map<String, dynamic>)['reviewStatus'] as String? ?? 'pending';
          counts[s] = (counts[s] ?? 0) + 1;
        }

        return Column(
          children: [
            _SummaryBar(counts: counts),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc  = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _SubmissionAuditCard(
                    data: data,
                    type: _SubmissionType.hadith,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── تصنيفات المشرف ────────────────────────────────────────────────────────────

class _UserCategoriesTab extends StatelessWidget {
  final String userId;
  const _UserCategoriesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_categories')
          .where('submittedBy', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.category_outlined,
            title: 'لم يُرسِل هذا المشرف أي تصنيف',
          );
        }

        final counts = <String, int>{};
        for (final d in docs) {
          final s = (d.data() as Map<String, dynamic>)['reviewStatus'] as String? ?? 'pending';
          counts[s] = (counts[s] ?? 0) + 1;
        }

        return Column(
          children: [
            _SummaryBar(counts: counts),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc  = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _SubmissionAuditCard(
                    data: data,
                    type: _SubmissionType.category,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final Map<String, int> counts;
  const _SummaryBar({required this.counts});

  @override
  Widget build(BuildContext context) {
    final pending  = counts['pending']  ?? 0;
    final approved = counts['approved'] ?? 0;
    final rejected = counts['rejected'] ?? 0;
    final total    = pending + approved + rejected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'الكل', value: total, color: AppColors.textPrimary),
          _Stat(label: 'معلّق', value: pending, color: const Color(0xFFD97706)),
          _Stat(label: 'مقبول', value: approved, color: AppColors.success),
          _Stat(label: 'مرفوض', value: rejected, color: AppColors.error),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Submission audit card ─────────────────────────────────────────────────────

enum _SubmissionType { hadith, category }

class _SubmissionAuditCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final _SubmissionType type;

  const _SubmissionAuditCard({
    required this.data,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['reviewStatus'] as String? ?? 'pending';
    final ts     = data['submittedAt'] as Timestamp?;
    final date   = ts != null ? _fmt(ts.toDate()) : '…';

    final title = type == _SubmissionType.hadith
        ? (data['title'] as String? ?? '')
        : (data['nameAr'] as String? ?? '');
    final subtitle = type == _SubmissionType.hadith
        ? (data['narrator'] as String? ?? '')
        : 'تصنيف';

    final (color, bg, label) = switch (status) {
      'approved' => (AppColors.success, const Color(0xFFECFDF5), 'مقبول'),
      'rejected' => (AppColors.error,   const Color(0xFFFEF2F2), 'مرفوض'),
      _          => (const Color(0xFFD97706), const Color(0xFFFEF3C7), 'معلّق'),
    };

    final rejectionReason = data['rejectionReason'] as String?;
    final approvedAt = data['approvedAt'] as Timestamp?;
    final rejectedAt = data['rejectedAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + date row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),

            // Title + subtitle
            Text(title, style: AppTextStyles.bodyBold),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: AppTextStyles.caption),

            // Approval/rejection timestamp
            if (status == 'approved' && approvedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'تاريخ القبول: ${_fmt(approvedAt.toDate())}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ],
            if (status == 'rejected') ...[
              if (rejectedAt != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.cancel_outlined,
                        size: 13, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'تاريخ الرفض: ${_fmt(rejectedAt.toDate())}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ],
              if (rejectionReason != null &&
                  rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: AppColors.error),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          rejectionReason,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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

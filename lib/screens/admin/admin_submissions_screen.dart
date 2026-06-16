import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import 'admin_guard.dart';

/// شاشة مشرف المحتوى لمتابعة مقدّماته (أحاديث وتصنيفات) وحالتها.
class AdminSubmissionsScreen extends StatefulWidget {
  const AdminSubmissionsScreen({super.key});

  @override
  State<AdminSubmissionsScreen> createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends State<AdminSubmissionsScreen>
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
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مقدّماتي'),
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
            _MyHadithSubmissions(),
            _MyCategorySubmissions(),
          ],
        ),
      ),
    );
  }
}

// ── أحاديثي المُرسَلة ────────────────────────────────────────────────────────

class _MyHadithSubmissions extends StatelessWidget {
  const _MyHadithSubmissions();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_hadiths')
          .where('submittedBy', isEqualTo: uid)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'لم تُرسِل أي حديث بعد',
            subtitle: 'اضغط على "إرسال حديث جديد" من الصفحة الرئيسية.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['reviewStatus'] as String? ?? 'pending';
            final ts = data['submittedAt'] as Timestamp?;
            final date = ts != null ? _fmt(ts.toDate()) : '…';
            final reason = data['rejectionReason'] as String?;

            return _SubmissionCard(
              title: data['title'] as String? ?? '',
              subtitle: data['narrator'] as String? ?? '',
              date: date,
              status: status,
              rejectionReason: reason,
            );
          },
        );
      },
    );
  }
}

// ── تصنيفاتي المُرسَلة ────────────────────────────────────────────────────────

class _MyCategorySubmissions extends StatelessWidget {
  const _MyCategorySubmissions();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_categories')
          .where('submittedBy', isEqualTo: uid)
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
            title: 'لم تُرسِل أي تصنيف بعد',
            subtitle: 'اضغط على "إرسال تصنيف جديد" من الصفحة الرئيسية.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['reviewStatus'] as String? ?? 'pending';
            final ts = data['submittedAt'] as Timestamp?;
            final date = ts != null ? _fmt(ts.toDate()) : '…';
            final reason = data['rejectionReason'] as String?;

            return _SubmissionCard(
              title: data['nameAr'] as String? ?? '',
              subtitle: 'تصنيف',
              date: date,
              status: status,
              rejectionReason: reason,
            );
          },
        );
      },
    );
  }
}

// ── Submission card ───────────────────────────────────────────────────────────

class _SubmissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String status;
  final String? rejectionReason;

  const _SubmissionCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'approved' => (AppColors.success, const Color(0xFFECFDF5), 'تم القبول'),
      'rejected' => (AppColors.error, const Color(0xFFFEF2F2), 'مرفوض'),
      _ => (const Color(0xFFD97706), const Color(0xFFFEF3C7), 'قيد المراجعة'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Text(label,
                      style: TextStyle(fontSize: 11, color: color)),
                ),
                const Spacer(),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.bodyBold),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
            if (status == 'rejected' && rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.error.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rejectionReason!,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  return '${d.day}/${d.month}/${d.year}';
}

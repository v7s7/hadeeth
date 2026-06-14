import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/hadith.dart';
import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/abandoned_badge.dart';
import '../../widgets/empty_state.dart';

/// شاشة تفاصيل الحديث: النص الكامل، الراوي، المصدر، الشرح، الفوائد،
/// الكلمات الغريبة، وأزرار الحفظ والتعلم والاختبار.
class HadithDetailsScreen extends StatefulWidget {
  final String hadithId;

  const HadithDetailsScreen({super.key, required this.hadithId});

  @override
  State<HadithDetailsScreen> createState() => _HadithDetailsScreenState();
}

class _HadithDetailsScreenState extends State<HadithDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackRead());
  }

  Future<void> _trackRead() async {
    final repository = context.read<HadithRepository>();
    final hadith = repository.getById(widget.hadithId);
    if (hadith == null) return;

    final progressService = context.read<ProgressService>();
    final isHadithOfDay = hadith.id == repository.hadithOfTheDay().id;
    final xpGained = await progressService.recordHadithRead(
      hadith.id,
      isHadithOfTheDay: isHadithOfDay,
    );

    if (xpGained > 0 && mounted) {
      _showSnackBar('+$xpGained XP');
    }
  }

  Future<void> _markLearned(Hadith hadith) async {
    final progressService = context.read<ProgressService>();
    final xpGained = await progressService.markHadithLearned(hadith.id);
    if (!mounted) return;

    final message = xpGained > 0 ? '+$xpGained XP - أحسنت!' : 'تم تسجيل هذا الحديث كمتعلم';
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HadithRepository>();
    final hadith = repository.getById(widget.hadithId);

    if (hadith == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'لم يتم العثور على الحديث',
        ),
      );
    }

    final progressService = context.watch<ProgressService>();
    final isFavorite = progressService.isFavorite(hadith.id);
    final isLearned = progressService.isLearned(hadith.id);
    final category = context.watch<CategoryRepository>().categoryById(hadith.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(hadith.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            onPressed: () => progressService.toggleFavorite(hadith.id),
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (category != null) _InfoChip(icon: category.icon, label: category.nameAr),
                _InfoChip(
                  icon: Icons.verified_outlined,
                  label: hadith.authenticityGrade.labelAr,
                  color: AppColors.success,
                ),
                _InfoChip(icon: Icons.bar_chart, label: hadith.difficultyLevel.labelAr),
                if (hadith.isAbandonedSunnah) const AbandonedBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  hadith.hadithText,
                  style: AppTextStyles.hadithText,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    _InfoRow(label: 'الراوي', value: hadith.narrator),
                    const Divider(height: 1),
                    _InfoRow(label: 'المصدر', value: hadith.fullSource),
                    const Divider(height: 1),
                    _InfoRow(label: 'الحكم', value: hadith.authenticityGrade.labelAr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'الشرح',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hadith.shortExplanation, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 8),
                  Text(hadith.detailedExplanation, style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'الفوائد',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: hadith.benefits.map((b) => _BulletItem(text: b)).toList(),
              ),
            ),
            if (hadith.strangeWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'كلمات غريبة',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: hadith.strangeWords
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: '${w.word}: ', style: AppTextStyles.bodyBold),
                                TextSpan(text: w.meaning, style: AppTextStyles.body),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLearned ? null : () => _markLearned(hadith),
              icon: Icon(isLearned ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(isLearned ? 'تم تعلم هذا الحديث' : 'تعلمت هذا الحديث'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/quiz/${hadith.id}'),
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('ابدأ الاختبار'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.badge.copyWith(color: chipColor)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyBold,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

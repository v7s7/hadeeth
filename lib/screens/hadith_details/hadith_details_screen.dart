import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/hadith.dart';
import '../../models/app_characters.dart';
import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../services/local_storage_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/abandoned_badge.dart';
import '../../widgets/completion_overlay.dart';
import '../../widgets/empty_state.dart';

/// شاشة تفاصيل الحديث: النص الكامل، الراوي، المصدر، الشرح، الفوائد،
/// الكلمات الغريبة، وأزرار الحفظ والتعلم والمشاركة والاختبار.
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
    final isHadithOfDay = hadith.id == repository.hadithOfTheDay()?.id;
    final xpGained = await progressService.recordHadithRead(
      hadith.id,
      isHadithOfTheDay: isHadithOfDay,
    );

    if (xpGained > 0 && mounted) {
      final boost = progressService.streakMultiplierLabel;
      final label = boost.isEmpty ? '+$xpGained XP' : '+$xpGained XP  $boost';
      _showSnackBar(label);
    }
  }

  Future<void> _markLearned(Hadith hadith) async {
    final progressService = context.read<ProgressService>();

    // Capture level BEFORE earning XP so we can detect level-up
    final levelBefore = progressService.currentLevel.level;

    final xpGained = await progressService.markHadithLearned(hadith.id);
    if (!mounted) return;

    final totalXpAfter = progressService.progress.totalXp;
    final levelAfter   = progressService.currentLevel.level;
    final newStreak    = progressService.progress.currentStreak;

    // Load selected character (cached from SharedPreferences)
    final charId    = LocalStorageService.cachedCharacterId
        ?? await LocalStorageService().loadCharacterId();
    final character = AppCharacters.findById(charId);

    if (!mounted) return;

    await showCompletionOverlay(
      context: context,
      xpGained: xpGained,
      newStreak: newStreak,
      totalXpAfter: totalXpAfter,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      character: character,
    );
  }

  void _shareHadith(Hadith hadith) {
    final text = 'قال رسول الله ﷺ:\n'
        '«${hadith.hadithText}»\n\n'
        'رواه: ${hadith.narrator}\n'
        'المصدر: ${hadith.fullSource}\n\n'
        '🕌 من تطبيق الحديث المهجور';
    Share.share(text, subject: 'حديث: ${hadith.title}');
  }

  void _copyHadith(Hadith hadith) {
    final text = '«${hadith.hadithText}»\n'
        'رواه: ${hadith.narrator} — ${hadith.fullSource}';
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ الحديث ✓');
  }

  void _openReadingMode(Hadith hadith) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReadingModeSheet(hadith: hadith),
    );
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
    final category =
        context.watch<CategoryRepository>().categoryById(hadith.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(hadith.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // نسخ
          IconButton(
            tooltip: 'نسخ',
            onPressed: () => _copyHadith(hadith),
            icon: const Icon(Icons.copy_outlined),
          ),
          // مشاركة
          IconButton(
            tooltip: 'مشاركة',
            onPressed: () => _shareHadith(hadith),
            icon: const Icon(Icons.share_outlined),
          ),
          // حفظ
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
                if (category != null)
                  _InfoChip(icon: category.icon, label: category.nameAr),
                _InfoChip(
                  icon: Icons.verified_outlined,
                  label: hadith.authenticityGrade.labelAr,
                  color: AppColors.success,
                ),
                _InfoChip(
                    icon: Icons.bar_chart, label: hadith.difficultyLevel.labelAr),
                if (hadith.isAbandonedSunnah) const AbandonedBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // ── نص الحديث مع زر وضع القراءة ──
            Stack(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 46),
                    child: Text(
                      hadith.hadithText,
                      style: AppTextStyles.hadithText.copyWith(height: 1.9),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: TextButton.icon(
                    onPressed: () => _openReadingMode(hadith),
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: const Text('وضع القراءة'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
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
                                TextSpan(
                                    text: '${w.word}: ',
                                    style: AppTextStyles.bodyBold),
                                TextSpan(
                                    text: w.meaning, style: AppTextStyles.body),
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

            // ── أزرار التعلم والاختبار ──
            ElevatedButton.icon(
              onPressed: isLearned ? null : () => _markLearned(hadith),
              icon: Icon(
                  isLearned ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(isLearned ? 'تم تعلم هذا الحديث' : 'تعلمت هذا الحديث'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/quiz/${hadith.id}'),
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('ابدأ الاختبار'),
            ),

            // ── أزرار المشاركة والنسخ (صف سفلي) ──
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyHadith(hadith),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('نسخ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareHadith(hadith),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('مشاركة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── وضع القراءة المريح ─────────────────────────────────────────────────────

class _ReadingModeSheet extends StatelessWidget {
  final Hadith hadith;
  const _ReadingModeSheet({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // مقبض السحب
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // شعار صغير
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '﷽',
                  style: AppTextStyles.hadithText.copyWith(
                    color: Colors.white38,
                    fontSize: 18,
                  ),
                ),
              ),
              // النص القابل للتمرير
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                  children: [
                    Text(
                      hadith.hadithText,
                      style: AppTextStyles.hadithText.copyWith(
                        color: const Color(0xFFF0EAD6),
                        fontSize: 22,
                        height: 2.0,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '— ${hadith.narrator}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white38,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      hadith.fullSource,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              // أزرار النسخ والمشاركة أسفل الورقة
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ReadingActionBtn(
                        icon: Icons.copy_outlined,
                        label: 'نسخ',
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  '«${hadith.hadithText}»\nرواه: ${hadith.narrator}'));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ الحديث ✓')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ReadingActionBtn(
                        icon: Icons.share_outlined,
                        label: 'مشاركة',
                        onTap: () {
                          Navigator.pop(context);
                          Share.share(
                            'قال رسول الله ﷺ:\n«${hadith.hadithText}»\n\n'
                            'رواه: ${hadith.narrator}\n${hadith.fullSource}\n\n'
                            '🕌 من تطبيق الحديث المهجور',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadingActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReadingActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// ── مكوّنات مشتركة ─────────────────────────────────────────────────────────

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

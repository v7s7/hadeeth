import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/progress_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/guest_banner.dart';
import '../../widgets/xp_progress_bar.dart';

const List<String> _weekdayShortNamesAr = [
  'إثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
  'أحد',
];

/// شاشة تقدّمي: ملخص النقاط والمستوى والسلسلة اليومية، والإحصائيات الشخصية.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final progressService = context.watch<ProgressService>();
    final progress = progressService.progress;
    final accuracy = (progress.quizAccuracy * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('تقدّمي')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (session.isGuest) ...[
              const GuestBanner(
                message: 'سجّل دخولك لحفظ تقدمك ومزامنته بين أجهزتك.',
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: XpProgressBar(
                  currentLevel: progressService.currentLevel,
                  nextLevel: progressService.nextLevel,
                  totalXp: progress.totalXp,
                  progress: progressService.levelProgressValue,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('نشاط آخر 7 أيام', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _WeeklyActivityChart(values: progressService.last7DaysXp()),
              ),
            ),
            const SizedBox(height: 20),
            Text('إحصائياتي', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatTile(
                  icon: Icons.local_fire_department,
                  label: 'السلسلة الحالية',
                  value: '${progress.currentStreak} يوم',
                ),
                _StatTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'أطول سلسلة',
                  value: '${progress.longestStreak} يوم',
                ),
                _StatTile(
                  icon: Icons.menu_book_outlined,
                  label: 'أحاديث متعلَّمة',
                  value: '${progress.learnedHadithIds.length}',
                ),
                _StatTile(
                  icon: Icons.quiz_outlined,
                  label: 'اختبارات مكتملة',
                  value: '${progress.quizzesCompleted}',
                ),
                _StatTile(
                  icon: Icons.track_changes_outlined,
                  label: 'دقة الإجابات',
                  value: '$accuracy%',
                ),
                _StatTile(
                  icon: Icons.bookmark_outline,
                  label: 'أحاديث محفوظة',
                  value: '${progress.savedHadithIds.length}',
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

class _WeeklyActivityChart extends StatelessWidget {
  final List<int> values;

  const _WeeklyActivityChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const maxBarHeight = 100.0;
    const maxValue = ProgressService.baseDailyXpCap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final day = now.subtract(Duration(days: values.length - 1 - i));
        final value = values[i];
        final ratio = value / maxValue > 1 ? 1.0 : value / maxValue;
        final isToday = i == values.length - 1;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value', style: AppTextStyles.caption, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: maxBarHeight * ratio + 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _weekdayShortNamesAr[day.weekday - 1],
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary),
          Text(
            value,
            style: AppTextStyles.screenTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

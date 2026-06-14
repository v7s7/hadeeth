import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/categories_data.dart';
import '../../models/hadith.dart';
import '../../services/hadith_repository.dart';
import '../../services/progress_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/abandoned_badge.dart';
import '../../widgets/guest_banner.dart';
import '../../widgets/hadith_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/xp_progress_bar.dart';

/// الشاشة الرئيسية: حديث اليوم، السلسلة، المستوى، وأقسام الأحاديث.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressService = context.watch<ProgressService>();
    final session = context.watch<SessionService>();
    final progress = progressService.progress;

    final repository = HadithRepository();
    final hadithOfDay = repository.hadithOfTheDay();
    final abandoned = repository.abandoned().take(5).toList();
    final recent = repository.recentlyAdded(limit: 5);

    return Scaffold(
      appBar: AppBar(title: const Text('الحديث المهجور')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (session.isGuest) ...[
              const GuestBanner(),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StreakBadge(streak: progress.currentStreak),
                const SizedBox(width: 12),
                Expanded(
                  child: XpProgressBar(
                    currentLevel: progressService.currentLevel,
                    nextLevel: progressService.nextLevel,
                    totalXp: progress.totalXp,
                    progress: progressService.levelProgressValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _HadithOfDayCard(hadith: hadithOfDay),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/hadith/${hadithOfDay.id}'),
                    child: const Text('ابدأ التعلم'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/quiz/${hadithOfDay.id}'),
                    child: const Text('اختبر نفسك'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'أحاديث مهجورة',
              onSeeAll: () => context.push('/category/abandoned_sunnah'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: abandoned.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    HadithCard(hadith: abandoned[index], width: 230),
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'آخر ما أضيف'),
            const SizedBox(height: 12),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    HadithCard(hadith: recent[index], width: 230),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// بطاقة "حديث اليوم" البارزة في أعلى الشاشة الرئيسية.
class _HadithOfDayCard extends StatelessWidget {
  final Hadith hadith;

  const _HadithOfDayCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    final category = categoryById(hadith.categoryId);

    return Card(
      color: AppColors.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/hadith/${hadith.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'حديث اليوم',
                    style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  if (hadith.isAbandonedSunnah) const AbandonedBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hadith.hadithText,
                style: AppTextStyles.hadithText.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                '${hadith.narrator} • ${hadith.fullSource}',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
              if (category != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.nameAr,
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/categories_data.dart';
import '../models/hadith.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'abandoned_badge.dart';

/// بطاقة عرض مختصرة لحديث، تُستخدم في القوائم الأفقية والرأسية.
class HadithCard extends StatelessWidget {
  final Hadith hadith;
  final double? width;

  const HadithCard({super.key, required this.hadith, this.width});

  @override
  Widget build(BuildContext context) {
    final category = categoryById(hadith.categoryId);
    final progressService = context.watch<ProgressService>();
    final isFavorite = progressService.isFavorite(hadith.id);

    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/hadith/${hadith.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (category != null) ...[
                      Icon(category.icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          category.nameAr,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Expanded(child: SizedBox.shrink()),
                    if (hadith.isAbandonedSunnah) const AbandonedBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hadith.title,
                  style: AppTextStyles.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${hadith.narrator} - ${hadith.sourceBook}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(hadith.difficultyLevel.labelAr, style: AppTextStyles.caption),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => progressService.toggleFavorite(hadith.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

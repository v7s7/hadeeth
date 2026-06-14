import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hadith.dart';
import '../../services/hadith_repository.dart';
import '../../services/progress_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hadith_card.dart';

/// شاشة المفضلة: الأحاديث المحفوظة من قبل المستخدم.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HadithRepository>();
    final progressService = context.watch<ProgressService>();
    final savedIds = progressService.progress.savedHadithIds;

    final hadiths = savedIds.map(repository.getById).whereType<Hadith>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: SafeArea(
        child: hadiths.isEmpty
            ? const EmptyState(
                icon: Icons.bookmark_border,
                title: 'لا توجد أحاديث محفوظة',
                subtitle: 'اضغط على أيقونة الحفظ في أي حديث لإضافته هنا',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: hadiths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => HadithCard(hadith: hadiths[index]),
              ),
      ),
    );
  }
}

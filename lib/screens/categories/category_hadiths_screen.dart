import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hadith_card.dart';

/// شاشة أحاديث تصنيف معيّن.
class CategoryHadithsScreen extends StatelessWidget {
  final String categoryId;

  const CategoryHadithsScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HadithRepository>();
    final category = context.watch<CategoryRepository>().categoryById(categoryId);
    final hadiths = repository.byCategory(categoryId);

    return Scaffold(
      appBar: AppBar(title: Text(category?.nameAr ?? 'التصنيف')),
      body: SafeArea(
        child: hadiths.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'لا توجد أحاديث في هذا التصنيف حتى الآن',
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

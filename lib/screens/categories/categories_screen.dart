import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/categories_data.dart';
import '../../services/hadith_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// شاشة التصنيفات: شبكة من بطاقات التصنيفات الثمانية.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = HadithRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: hadithCategories.length,
          itemBuilder: (context, index) {
            final category = hadithCategories[index];
            final count = repository.byCategory(category.id).length;

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/category/${category.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category.icon, color: AppColors.primary),
                      ),
                      Text(category.nameAr, style: AppTextStyles.cardTitle),
                      Text('$count حديث', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

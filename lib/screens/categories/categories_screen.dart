import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ── Amber accent used only for the terminology button ──────────────────────
const _kAmber = Color(0xFFB45309);
const _kAmberLight = Color(0xFFFEF3C7);

// ── Hadith science terms ────────────────────────────────────────────────────
const _terms = [
  _Term('صحيح',
      'الحديث الذي اتصل سنده برواية عدلٍ تامّ الضبط عن مثله إلى منتهاه، من غير شذوذٍ ولا علة.'),
  _Term('حسن',
      'الحديث الذي اتصل سنده برواية عدلٍ خفيف الضبط عن مثله، من غير شذوذٍ ولا علة.'),
  _Term('ضعيف',
      'الحديث الذي لم يجمع صفات الصحيح ولا الحسن، لخللٍ في الإسناد أو المتن.'),
  _Term('موضوع',
      'الحديث المكذوب المختلَق المنسوب إلى النبي ﷺ، وهو شرّ أنواع الضعيف.'),
  _Term('مرسَل',
      'ما رفعه التابعي مباشرةً إلى النبي ﷺ دون ذكر الصحابي.'),
  _Term('منقطع',
      'الحديث الذي سقط من سنده راوٍ أو أكثر في غير موضع الصحابي.'),
  _Term('معضَل',
      'الحديث الذي سقط من سنده راويان متتاليان فأكثر.'),
  _Term('متواتر',
      'ما رواه جمعٌ عن جمع تحيل العادةُ تواطؤَهم على الكذب، وأفاد العلم اليقيني.'),
  _Term('آحاد',
      'كل حديث لم يبلغ درجة التواتر، سواء رواه واحد أو أكثر.'),
  _Term('مسند',
      'الحديث المرفوع بسندٍ متصل إلى النبي ﷺ.'),
  _Term('مرفوع',
      'ما نُسب إلى النبي ﷺ من قولٍ أو فعلٍ أو تقريرٍ أو صفة.'),
  _Term('موقوف',
      'ما نُسب إلى الصحابي رضي الله عنه من قولٍ أو فعلٍ أو تقرير.'),
  _Term('مقطوع',
      'ما نُسب إلى التابعي من قولٍ أو فعلٍ أو تقرير.'),
  _Term('شاذّ',
      'ما رواه الثقة مخالفاً لمن هو أوثق منه.'),
  _Term('منكَر',
      'ما رواه الضعيف مخالفاً للثقة.'),
  _Term('مدلَّس',
      'ما أوهم راويه فيه أن له سنداً أعلى مما هو في الحقيقة.'),
  _Term('مُعلَّل',
      'الحديث الذي فيه علةٌ خفية قادحة يُكشف عنها بجمع الطرق ودراسة الأسانيد.'),
  _Term('مضطرب',
      'الحديث الذي يُروى على أوجهٍ مختلفة متساوية لا يمكن الجمع بينها.'),
];

class _Term {
  final String name;
  final String definition;
  const _Term(this.name, this.definition);
}

// ── Main screen ─────────────────────────────────────────────────────────────

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HadithRepository>();
    final categories = context.watch<CategoryRepository>().visibleCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Terminology button ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: _TerminologyButton(
                  onTap: () => _showTerminologySheet(context),
                ),
              ),
            ),

            // ── Categories grid ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    final count = repository.byCategory(category.id).length;
                    return _CategoryCard(category: category, count: count);
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerminologySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TerminologySheet(),
    );
  }
}

// ── Terminology button ───────────────────────────────────────────────────────

class _TerminologyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TerminologyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kAmberLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD97706).withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: _kAmber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مصطلحات في علم الحديث',
                        style: AppTextStyles.cardTitle
                            .copyWith(color: _kAmber, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تعرّف على مصطلحات الحديث النبوي',
                        style: AppTextStyles.caption
                            .copyWith(color: _kAmber.withOpacity(0.75)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _kAmber, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category card (unchanged logic, extracted) ───────────────────────────────

class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final int count;
  const _CategoryCard({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
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
  }
}

// ── Terminology bottom sheet ─────────────────────────────────────────────────

class _TerminologySheet extends StatelessWidget {
  const _TerminologySheet();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _kAmberLight,
                  border: Border(
                      bottom: BorderSide(color: _kAmber.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: _kAmber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مصطلحات في علم الحديث',
                        style: AppTextStyles.sectionTitle
                            .copyWith(color: _kAmber),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _kAmber, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Terms list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, 16 + topPad),
                  itemCount: _terms.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 8, endIndent: 8),
                  itemBuilder: (context, index) {
                    final term = _terms[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Term name pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kAmberLight,
                              border:
                                  Border.all(color: _kAmber.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              term.name,
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: _kAmber, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Definition
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                term.definition,
                                style: AppTextStyles.body
                                    .copyWith(height: 1.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

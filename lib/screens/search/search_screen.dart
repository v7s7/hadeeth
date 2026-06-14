import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/hadith_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hadith_card.dart';

enum _SearchFilter { all, abandonedOnly, myRead, recent }

/// شاشة البحث مع فلاتر: السنن المهجورة، قرأتها، الأحدث إضافة.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  _SearchFilter _filter = _SearchFilter.all;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HadithRepository>();
    final progressService = context.watch<ProgressService>();
    final readIds = progressService.progress.readHadithIds;

    var results = repository.search(
      _query,
      abandonedOnly: _filter == _SearchFilter.abandonedOnly,
    );

    switch (_filter) {
      case _SearchFilter.recent:
        results = [...results]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SearchFilter.myRead:
        // أظهر الأحاديث التي قرأها المستخدم أولاً، ثم الباقي.
        results = [...results]..sort((a, b) {
            final aRead = readIds.contains(a.id) ? 0 : 1;
            final bRead = readIds.contains(b.id) ? 0 : 1;
            return aRead.compareTo(bRead);
          });
      default:
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth > 900
                ? (constraints.maxWidth - 900) / 2
                : 0.0;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(side + 16, 8, side + 16, 0),
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث في نص الحديث، الراوي، المصدر أو التصنيف',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: side + 16),
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: _filter == _SearchFilter.all,
                        onSelected: () => setState(() => _filter = _SearchFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'السنن المهجورة',
                        selected: _filter == _SearchFilter.abandonedOnly,
                        onSelected: () =>
                            setState(() => _filter = _SearchFilter.abandonedOnly),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'قرأتها',
                        selected: _filter == _SearchFilter.myRead,
                        onSelected: () =>
                            setState(() => _filter = _SearchFilter.myRead),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'الأحدث إضافة',
                        selected: _filter == _SearchFilter.recent,
                        onSelected: () =>
                            setState(() => _filter = _SearchFilter.recent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: results.isEmpty
                      ? const EmptyState(
                          imagePath: 'assets/images/empty_states/empty_search.png',
                          title: 'لا توجد نتائج',
                          subtitle: 'جرّب كلمة بحث أخرى أو غيّر الفلتر',
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(side + 16, 0, side + 16, 16),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              HadithCard(hadith: results[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: AppTextStyles.caption.copyWith(
        color: selected ? Colors.white : AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}

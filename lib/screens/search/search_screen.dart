import 'package:flutter/material.dart';

import '../../services/hadith_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hadith_card.dart';

enum _SearchFilter { all, abandonedOnly, mostRead, recent }

/// شاشة البحث مع فلاتر: السنن المهجورة، الأكثر قراءة، الأحدث إضافة.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final HadithRepository _repository = HadithRepository();
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
    var results = _repository.search(
      _query,
      abandonedOnly: _filter == _SearchFilter.abandonedOnly,
    );

    if (_filter == _SearchFilter.recent) {
      results = [...results]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: _filter == _SearchFilter.all,
                    onSelected: () => setState(() => _filter = _SearchFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'فقط الأحاديث المهجورة',
                    selected: _filter == _SearchFilter.abandonedOnly,
                    onSelected: () => setState(() => _filter = _SearchFilter.abandonedOnly),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'الأكثر قراءة',
                    selected: _filter == _SearchFilter.mostRead,
                    onSelected: () => setState(() => _filter = _SearchFilter.mostRead),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'الأحدث إضافة',
                    selected: _filter == _SearchFilter.recent,
                    onSelected: () => setState(() => _filter = _SearchFilter.recent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'لا توجد نتائج',
                      subtitle: 'جرّب كلمة بحث أخرى أو غيّر الفلتر',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => HadithCard(hadith: results[index]),
                    ),
            ),
          ],
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

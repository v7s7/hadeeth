import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_accessory.dart';
import '../../models/app_characters.dart';
import '../../models/user_progress.dart';
import '../../services/local_storage_service.dart';
import '../../services/progress_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/accessory_tile.dart';
import '../../widgets/character_avatar.dart';

/// خزانة الشخصية: كل الإكسسوارات مجمّعة حسب نوعها، مع معاينة مباشرة
/// للشخصية وإمكانية تبديل المرافق الحالي بلمسة واحدة.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _storage = LocalStorageService();
  String? _activeAccessoryId;

  @override
  void initState() {
    super.initState();
    _loadActiveAccessory();
  }

  Future<void> _loadActiveAccessory() async {
    final id = await _storage.loadActiveAccessoryId();
    if (mounted) setState(() => _activeAccessoryId = id);
  }

  Future<void> _select(AppAccessory accessory, SessionService session) async {
    setState(() => _activeAccessoryId = accessory.id);
    await _storage.saveActiveAccessoryId(accessory.id);
    await session.saveActiveAccessory(accessory.id);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final progress = context.watch<ProgressService>().progress;

    final active = AppAccessories.findById(
            session.activeAccessoryId ?? _activeAccessoryId) ??
        AppAccessories.defaultAccessory();
    final character = AppCharacters.findById(session.characterId) ??
        (session.gender != null
            ? AppCharacters.defaultFor(session.gender!)
            : null);

    return Scaffold(
      appBar: AppBar(title: const Text('خزانة الشخصية')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth > 900
                ? (constraints.maxWidth - 900) / 2
                : 0.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(side + 16, 16, side + 16, 24),
              children: [
                _PreviewHeader(character: character, active: active),
                const SizedBox(height: 20),
                for (final category in AccessoryCategory.values)
                  _CategorySection(
                    category: category,
                    items: AppAccessories.all
                        .where((a) => a.category == category)
                        .toList(),
                    activeId: active.id,
                    progress: progress,
                    onSelect: (accessory) => _select(accessory, session),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  final CharacterOption? character;
  final AppAccessory active;

  const _PreviewHeader({required this.character, required this.active});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            if (character != null)
              CharacterAvatar(
                character: character!,
                height: 170,
                accessory: active,
              )
            else
              const SizedBox(height: 170),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: active.color, size: 20),
                const SizedBox(width: 8),
                Text(active.nameAr, style: AppTextStyles.sectionTitle),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              active.descriptionAr,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AccessoryCategory category;
  final List<AppAccessory> items;
  final String activeId;
  final UserProgress progress;
  final ValueChanged<AppAccessory> onSelect;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.activeId,
    required this.progress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(category.icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(category.labelAr, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 112,
              mainAxisExtent: 150,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final accessory = items[index];
              final unlocked = accessory.isUnlocked(progress);
              final selected = accessory.id == activeId;
              return AccessoryTile(
                accessory: accessory,
                selected: selected,
                unlocked: unlocked,
                hint: accessory.unlockHint(progress),
                onTap: unlocked ? () => onSelect(accessory) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

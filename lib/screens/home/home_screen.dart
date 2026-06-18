import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/hadith.dart';
import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../services/local_storage_service.dart';
import '../../services/progress_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/app_accessory.dart';
import '../../models/app_level.dart';
import '../../models/app_characters.dart';
import '../../models/user_gender.dart';
import '../../models/user_progress.dart';
import '../../widgets/abandoned_badge.dart';
import '../../widgets/daily_goal_card.dart';
import '../../widgets/guest_banner.dart';
import '../../widgets/hadith_card.dart';
import '../../widgets/save_progress_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/character_avatar.dart';

/// الشاشة الرئيسية: الشخصية الترحيبية، السلسلة، الهدف اليومي،
/// حديث اليوم، والأقسام المختلفة.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressService = context.watch<ProgressService>();
    final session = context.watch<SessionService>();
    final progress = progressService.progress;

    final repository = context.watch<HadithRepository>();

    // ── شاشة تحميل — حتى يصل أول رد من Firestore ──
    if (!repository.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('الحديث المهجور')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hadithOfDay = repository.hadithOfTheDay();
    final abandoned = repository.abandoned().take(5).toList();
    final recent = repository.recentlyAdded(limit: 5);

    // ── شاشة "لا محتوى بعد" إذا لم ينشر المشرف أي أحاديث ──
    if (hadithOfDay == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الحديث المهجور')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 72, color: AppColors.primary.withOpacity(0.4)),
              const SizedBox(height: 20),
              Text(
                'قريبًا...',
                style: AppTextStyles.screenTitle
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'يعمل فريقنا على إضافة الأحاديث\nتابعنا قريبًا',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الحديث المهجور')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth > 900
                ? (constraints.maxWidth - 900) / 2
                : 0.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(side + 16, 16, side + 16, 16),
              children: [
                SignupNudge(isGuest: session.isGuest, progress: progress),
                if (session.isGuest) ...[
                  GuestBanner(onTap: () => context.push('/register')),
                  const SizedBox(height: 16),
                ],

                // ── شخصية الترحيب ──
                _CharacterGreetingCard(
                  session: session,
                  appLevel: progressService.currentLevel,
                  progress: progress,
                ),
                const SizedBox(height: 16),

                // ── شريط السلسلة والـ XP ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreakBadge(
                      streak: progress.currentStreak,
                      multiplierLabel:
                          progressService.streakMultiplierLabel,
                    ),
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
                const SizedBox(height: 16),

                // ── بطاقة الهدف اليومي ──
                DailyGoalCard(progressService: progressService),
                const SizedBox(height: 20),

                // ── حديث اليوم ──
                _HadithOfDayCard(hadith: hadithOfDay),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push('/hadith/${hadithOfDay.id}'),
                        child: const Text('ابدأ التعلم'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.push('/quiz/${hadithOfDay.id}'),
                        child: const Text('اختبر نفسك'),
                      ),
                    ),
                  ],
                ),

                if (abandoned.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'أحاديث مهجورة',
                    onSeeAll: () =>
                        context.push('/category/abandoned_sunnah'),
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
                ],

                if (recent.isNotEmpty) ...[
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
                ],

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── بطاقة الشخصية الترحيبية ─────────────────────────────────────────────────

class _CharacterGreetingCard extends StatefulWidget {
  final SessionService session;
  final AppLevel appLevel;
  final UserProgress progress;

  const _CharacterGreetingCard({
    required this.session,
    required this.appLevel,
    required this.progress,
  });

  @override
  State<_CharacterGreetingCard> createState() => _CharacterGreetingCardState();
}

class _CharacterGreetingCardState extends State<_CharacterGreetingCard> {
  UserGender? _gender;
  CharacterOption? _character;
  AppAccessory? _accessory;
  String? _preferredName;

  @override
  void initState() {
    super.initState();
    final instant = widget.session.gender ?? LocalStorageService.cachedGender;
    if (instant != null) {
      _gender = instant;
    }
    _preferredName = widget.session.displayName ??
        LocalStorageService.cachedPreferredName;
    _loadData();
  }

  @override
  void didUpdateWidget(_CharacterGreetingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.gender != oldWidget.session.gender ||
        widget.session.characterId != oldWidget.session.characterId ||
        widget.session.activeAccessoryId != oldWidget.session.activeAccessoryId ||
        widget.session.displayName != oldWidget.session.displayName) {
      setState(() {
        if (widget.session.gender != null) _gender = widget.session.gender;
        _character = AppCharacters.findById(widget.session.characterId) ??
            _character;
        _accessory = AppAccessories.findById(
              widget.session.activeAccessoryId,
            ) ??
            _accessory;
        _preferredName = widget.session.displayName ?? _preferredName;
      });
    }
  }

  Future<void> _loadData() async {
    final storage = LocalStorageService();
    final gender = widget.session.gender ?? await storage.loadGender();
    final id = widget.session.characterId ??
        LocalStorageService.cachedCharacterId ??
        await storage.loadCharacterId();
    final accessoryId = widget.session.activeAccessoryId ??
        LocalStorageService.cachedActiveAccessoryId ??
        await storage.loadActiveAccessoryId();
    final name = widget.session.displayName ??
        LocalStorageService.cachedPreferredName ??
        await storage.loadPreferredName();
    final char = AppCharacters.findById(id) ??
        (gender != null ? AppCharacters.defaultFor(gender) : null);
    final accessory = AppAccessories.findById(accessoryId) ??
        AppAccessories.defaultAccessory();
    if (mounted) {
      setState(() {
        _gender = gender;
        _character = char;
        _accessory = accessory;
        _preferredName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gender = _gender;

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: gender != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: gender != null ? _buildCard(gender) : const SizedBox.shrink(),
      ),
    );
  }


  String _characterTalk(UserProgress progress, String characterName) {
    if (progress.currentStreak >= 7) {
      return 'أنا $characterName، سلسلتك ${progress.currentStreak} أيام — واصل!';
    }
    if (progress.dailyXpEarned > 0) {
      return 'أنا $characterName، بداية موفقة اليوم ✨';
    }
    return 'أنا $characterName، جاهز أرافقك اليوم؟';
  }

  Widget _buildCard(UserGender gender) {
    final primary = Color(gender.primaryColorValue);
    final secondary = Color(gender.secondaryColorValue);
    final glow = Color(gender.glowColorValue);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
            ? 'مساء الخير'
            : 'مساء النور';

    final name = (_preferredName != null && _preferredName!.trim().isNotEmpty)
        ? _preferredName!.trim()
        : gender.welcomeText.split('،').last.trim();
    final talk = _character == null
        ? 'اختر شخصية ترافقك في رحلتك اليومية'
        : _characterTalk(widget.progress, _character!.labelAr);
    final characterLabel = _character?.labelAr ?? 'الشخصية';
    final accessory = _accessory ?? AppAccessories.defaultAccessory();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/welcome'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: secondary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          if (_character != null)
            Semantics(
              label: 'الشخصية المختارة: $characterLabel',
              image: true,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.96, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: CharacterAvatar(
                  character: _character!,
                  height: 64,
                  width: 52,
                  accessory: accessory,
                ),
              ),
            )
          else
            const SizedBox(width: 52, height: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$greeting، $name',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  '$talk\nالمستوى ${widget.appLevel.level} • ${widget.appLevel.titleAr}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded,
                  color: glow.withOpacity(0.5), size: 20),
              const SizedBox(height: 4),
              Text(
                'تغيير',
                style: AppTextStyles.caption.copyWith(
                  color: secondary.withOpacity(0.85),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ── بطاقة حديث اليوم ────────────────────────────────────────────────────────

class _HadithOfDayCard extends StatelessWidget {
  final Hadith hadith;

  const _HadithOfDayCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    final category =
        context.watch<CategoryRepository>().categoryById(hadith.categoryId);

    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
      ),
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
                  const Icon(Icons.wb_sunny_outlined, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'حديث اليوم',
                    style:
                        AppTextStyles.sectionTitle.copyWith(color: Colors.white),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

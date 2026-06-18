import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_accessory.dart';
import '../../models/user_progress.dart';
import '../../services/font_size_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/progress_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/guest_banner.dart';
import '../../widgets/streak_badge.dart';

/// شاشة حسابي: بيانات المستخدم، ملخص التقدم، الإعدادات، ومعلومات التطبيق.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = LocalStorageService();
  bool _notifEnabled = false;
  int _notifHour = 8;
  int _notifMinute = 0;
  int _dailyGoal = 3;
  String? _activeAccessoryId;
  NotificationTone _notificationTone = NotificationTone.gentle;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await _storage.areNotificationsEnabled();
    final hour = await _storage.getNotificationHour();
    final minute = await _storage.getNotificationMinute();
    final goal = await _storage.getDailyGoal();
    final accessoryId = await _storage.loadActiveAccessoryId();
    final tone = await _storage.getNotificationTone();
    if (mounted) {
      setState(() {
        _notifEnabled = enabled;
        _notifHour = hour;
        _notifMinute = minute;
        _dailyGoal = goal;
        _activeAccessoryId = accessoryId;
        _notificationTone = tone;
      });
    }
  }

  String? _notificationName() {
    final session = context.read<SessionService>();
    return session.displayName ?? LocalStorageService.cachedPreferredName;
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يرجى السماح بالإشعارات من إعدادات الجهاز')),
        );
        return;
      }
      await NotificationService.scheduleDailyReminder(
        TimeOfDay(hour: _notifHour, minute: _notifMinute),
        userName: _notificationName(),
        tone: _notificationTone,
      );
    } else {
      await NotificationService.cancelReminder();
    }
    await _storage.setNotificationsEnabled(value);
    if (mounted) setState(() => _notifEnabled = value);
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
      helpText: 'اختر وقت التذكير',
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _notifHour = picked.hour;
      _notifMinute = picked.minute;
    });
    await _storage.saveNotificationTime(picked.hour, picked.minute);
    if (_notifEnabled) {
      await NotificationService.scheduleDailyReminder(
        picked,
        userName: _notificationName(),
        tone: _notificationTone,
      );
    }
  }


  Future<void> _setNotificationTone(NotificationTone tone) async {
    setState(() => _notificationTone = tone);
    await _storage.saveNotificationTone(tone);
    if (_notifEnabled) {
      await NotificationService.scheduleDailyReminder(
        TimeOfDay(hour: _notifHour, minute: _notifMinute),
        userName: _notificationName(),
        tone: tone,
      );
    }
  }

  Future<void> _setDailyGoal(int goal) async {
    setState(() => _dailyGoal = goal);
    await _storage.setDailyGoal(goal);
  }

  Future<void> _setActiveAccessory(
    AppAccessory accessory,
    SessionService session,
  ) async {
    setState(() => _activeAccessoryId = accessory.id);
    await _storage.saveActiveAccessoryId(accessory.id);
    await session.saveActiveAccessory(accessory.id);
  }

  Future<void> _buyStreakFreeze(ProgressService progressService) async {
    final success = await progressService.buyStreakFreeze();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'تم شراء تجميد السلسلة ✓'
            : 'نقاطك غير كافية — تحتاج ${ProgressService.streakFreezeXpCost} XP'),
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _InfoSheet(title: title, body: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final progressService = context.watch<ProgressService>();
    final fontService = context.watch<FontSizeService>();
    final progress = progressService.progress;

    final notifTimeLabel =
        '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side =
                constraints.maxWidth > 900 ? (constraints.maxWidth - 900) / 2 : 0.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(side + 16, 16, side + 16, 16),
              children: [
                _ProfileHeader(session: session),
                const SizedBox(height: 16),
                if (session.isGuest) ...[
                  const GuestBanner(
                    message:
                        'سجّل دخولك لحفظ تقدمك على جميع أجهزتك ومزامنة سلسلتك اليومية.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── ملخص التقدم ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        StreakBadge(
                          streak: progress.currentStreak,
                          multiplierLabel:
                              progressService.streakMultiplierLabel,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المستوى ${progressService.currentLevel.level} • '
                                '${progressService.currentLevel.titleAr}',
                                style: AppTextStyles.bodyBold,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${progress.totalXp} نقطة خبرة',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.bar_chart,
                  title: 'تقدّمي',
                  subtitle: 'الإنجازات، الإحصائيات والنشاط الأسبوعي',
                  onTap: () => context.push('/progress'),
                ),
                _MenuTile(
                  icon: Icons.face_retouching_natural_outlined,
                  title: 'الشخصية والاسم',
                  subtitle: 'غيّر اسم الترحيب والشخصية التي ترافقك',
                  onTap: () => context.push('/welcome'),
                ),
                _AccessoryPickerCard(
                  activeAccessoryId:
                      session.activeAccessoryId ?? _activeAccessoryId,
                  progress: progress,
                  onSelect: (accessory) =>
                      _setActiveAccessory(accessory, session),
                ),
                if (session.isAnyAdmin)
                  _MenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'لوحة التحكم',
                    subtitle: session.isSuperAdmin
                        ? 'إدارة الأحاديث والتصنيفات والمستخدمين'
                        : 'إرسال محتوى للمراجعة ومتابعة مقدّماتك',
                    onTap: () => context.push('/admin'),
                  ),

                // ── حجم الخط ──────────────────────────────────────────────
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.format_size,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Text('حجم الخط', style: AppTextStyles.bodyBold),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: FontScaleOption.values.map((opt) {
                            final selected = fontService.option == opt;
                            return GestureDetector(
                              onTap: () => fontService.setOption(opt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  opt.labelAr,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13 * opt.scale,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        // معاينة
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'إنما الأعمال بالنيات',
                            style: AppTextStyles.hadithText.copyWith(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── الهدف اليومي ───────────────────────────────────────────
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.flag_outlined,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Text('الهدف اليومي', style: AppTextStyles.bodyBold),
                            const Spacer(),
                            Text(
                              '$_dailyGoal أحاديث',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [1, 3, 5, 10].map((goal) {
                            final selected = _dailyGoal == goal;
                            return GestureDetector(
                              onTap: () => _setDailyGoal(goal),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$goal',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── تجميد السلسلة ──────────────────────────────────────────
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            const Text('🧊', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Text('تجميد السلسلة', style: AppTextStyles.bodyBold),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '× ${progressService.streakFreezeCount}',
                                style: AppTextStyles.badge
                                    .copyWith(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يحمي سلسلتك اليومية لمدة يوم واحد عند انقطاعها.',
                          style: AppTextStyles.caption,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _buyStreakFreeze(progressService),
                            icon: const Text('🧊'),
                            label: Text(
                                'شراء تجميد — ${ProgressService.streakFreezeXpCost} XP'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── تذكير يومي ──────────────────────────────────────────────
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined,
                            color: AppColors.primary),
                        title: Text('تذكير حديث اليوم',
                            style: AppTextStyles.bodyBold),
                        subtitle: Text(
                          _notifEnabled
                              ? 'مفعّل يوميًا في $notifTimeLabel'
                              : 'غير مفعّل',
                          style: AppTextStyles.caption,
                        ),
                        value: _notifEnabled,
                        activeColor: AppColors.primary,
                        onChanged: _toggleNotifications,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: NotificationTone.values.map((tone) {
                            final selected = _notificationTone == tone;
                            return ChoiceChip(
                              label: Text(tone.labelAr),
                              selected: selected,
                              onSelected: (_) => _setNotificationTone(tone),
                              selectedColor: AppColors.primaryLight,
                              labelStyle: AppTextStyles.caption.copyWith(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_notifEnabled) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.access_time,
                              color: AppColors.primary),
                          title: Text('وقت التذكير', style: AppTextStyles.body),
                          trailing: Text(
                            notifTimeLabel,
                            style: AppTextStyles.bodyBold
                                .copyWith(color: AppColors.primary),
                          ),
                          onTap: _pickNotificationTime,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── معلومات ──────────────────────────────────────────────────
                _MenuTile(
                  icon: Icons.info_outline,
                  title: 'عن التطبيق',
                  onTap: () => _showInfoSheet(
                    context,
                    'عن التطبيق',
                    'الحديث المهجور هو تطبيق مجاني يهدف إلى تعريف المستخدمين بالأحاديث '
                        'الصحيحة والسنن المهجورة، عبر القراءة اليومية، الشرح المبسّط، '
                        'والاختبارات القصيرة، مع نظام نقاط وسلسلة تعلم يومية لتشجيع '
                        'الاستمرارية.',
                  ),
                ),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'سياسة الخصوصية',
                  onTap: () => _showInfoSheet(
                    context,
                    'سياسة الخصوصية',
                    'يحفظ التطبيق تقدّمك (النقاط، السلسلة اليومية، والأحاديث المحفوظة) '
                        'على جهازك. عند تسجيل الدخول بحساب، تتم مزامنة هذه البيانات '
                        'لحفظها وإتاحتها على أجهزتك الأخرى. لا تتم مشاركة بياناتك مع '
                        'أي طرف ثالث.',
                  ),
                ),
                if (!session.isGuest)
                  _MenuTile(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    titleColor: AppColors.error,
                    onTap: () => session.signOut(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── مكوّنات داخلية ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final SessionService session;

  const _ProfileHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final localName = LocalStorageService.cachedPreferredName;
    final name = session.isGuest
        ? (localName == null || localName.isEmpty ? 'زائر' : localName)
        : (session.displayName ?? localName ?? 'مستخدم');
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            session.isGuest ? Icons.person_outline : Icons.person,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: AppTextStyles.screenTitle),
                if (session.isSuperAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'مشرف عام',
                      style: AppTextStyles.badge
                          .copyWith(color: AppColors.accentDark),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              session.isGuest ? 'وضع الزائر' : 'حساب مسجّل',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppColors.primary),
        title: Text(
          title,
          style: AppTextStyles.bodyBold.copyWith(color: titleColor),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTextStyles.caption)
            : null,
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

class _AccessoryPickerCard extends StatelessWidget {
  final String? activeAccessoryId;
  final UserProgress progress;
  final ValueChanged<AppAccessory> onSelect;

  const _AccessoryPickerCard({
    required this.activeAccessoryId,
    required this.progress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final active = AppAccessories.findById(activeAccessoryId) ??
        AppAccessories.defaultAccessory();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.auto_awesome, color: active.color, size: 22),
                const SizedBox(width: 10),
                Text('رفيق الشخصية', style: AppTextStyles.bodyBold),
                const Spacer(),
                Text(active.nameAr, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'اختر مسباحًا أو لمسة صغيرة تظهر بجانب شخصيتك.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 134,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemBuilder: (context, index) {
                  final accessory = AppAccessories.all[index];
                  final unlocked = accessory.isUnlocked(progress);
                  final selected = active.id == accessory.id;
                  return _AccessoryOption(
                    accessory: accessory,
                    selected: selected,
                    unlocked: unlocked,
                    hint: accessory.unlockHint(progress),
                    onTap: unlocked ? () => onSelect(accessory) : null,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: AppAccessories.all.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessoryOption extends StatelessWidget {
  final AppAccessory accessory;
  final bool selected;
  final bool unlocked;
  final String hint;
  final VoidCallback? onTap;

  const _AccessoryOption({
    required this.accessory,
    required this.selected,
    required this.unlocked,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? accessory.color : AppColors.textMuted;

    return Semantics(
      button: unlocked,
      selected: selected,
      label: '${accessory.nameAr}، $hint',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 104,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.18)
                : color.withOpacity(unlocked ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.22),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.36,
                child: Image.asset(accessory.imagePath, width: 36, height: 36),
              ),
              const SizedBox(height: 6),
              Text(
                accessory.nameAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selected ? 'مختار' : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? color : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSheet({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.screenTitle),
            const SizedBox(height: 12),
            Text(body, style: AppTextStyles.body),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

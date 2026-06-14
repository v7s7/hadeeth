import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final enabled = await _storage.areNotificationsEnabled();
    final hour = await _storage.getNotificationHour();
    final minute = await _storage.getNotificationMinute();
    if (mounted) {
      setState(() {
        _notifEnabled = enabled;
        _notifHour = hour;
        _notifMinute = minute;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى السماح بالإشعارات من إعدادات الجهاز'),
          ),
        );
        return;
      }
      await NotificationService.scheduleDailyReminder(
        TimeOfDay(hour: _notifHour, minute: _notifMinute),
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
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _notifHour = picked.hour;
      _notifMinute = picked.minute;
    });

    await _storage.saveNotificationTime(picked.hour, picked.minute);

    if (_notifEnabled) {
      await NotificationService.scheduleDailyReminder(picked);
    }
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
    final progress = progressService.progress;

    final notifTimeLabel =
        '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth > 900
                ? (constraints.maxWidth - 900) / 2
                : 0.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(side + 16, 16, side + 16, 16),
              children: [
            _ProfileHeader(session: session),
            const SizedBox(height: 16),
            if (session.isGuest) ...[
              const GuestBanner(
                message: 'سجّل دخولك لحفظ تقدمك على جميع أجهزتك ومزامنة سلسلتك اليومية.',
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    StreakBadge(streak: progress.currentStreak),
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
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.bar_chart,
              title: 'تقدّمي',
              subtitle: 'الإنجازات، الإحصائيات والنشاط الأسبوعي',
              onTap: () => context.push('/progress'),
            ),
            if (session.isSuperAdmin)
              _MenuTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'لوحة التحكم',
                subtitle: 'إدارة الأحاديث والتصنيفات والمستخدمين',
                onTap: () => context.push('/admin'),
              ),

            // ── تذكير يومي ──
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'تذكير حديث اليوم',
                      style: AppTextStyles.bodyBold,
                    ),
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
                  if (_notifEnabled) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: AppColors.primary,
                      ),
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

class _ProfileHeader extends StatelessWidget {
  final SessionService session;

  const _ProfileHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final name = session.isGuest ? 'زائر' : (session.displayName ?? 'مستخدم');

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
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

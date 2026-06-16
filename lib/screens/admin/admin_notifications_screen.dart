import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/fcm_v1_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_guard.dart';

/// شاشة إرسال إشعار لجميع المستخدمين — FCM HTTP v1 (مجاني، بدون Cloud Functions).
///
/// الإعداد مرة واحدة:
///   1. Firebase Console → Project Settings → Service Accounts
///      → «Generate new private key» → حمّل ملف JSON
///   2. Firestore Console → أنشئ مستند:  config / fcm_v1
///      → أضف حقل:  serviceAccountJson  (نوعه String)
///      → الصق محتوى ملف JSON كاملاً في القيمة
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool _sending = false;
  bool _loading = true;
  FcmV1Service? _fcm; // null = not configured yet

  @override
  void initState() {
    super.initState();
    _loadServiceAccount();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServiceAccount() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('fcm_v1')
          .get();

      final raw = doc.data()?['serviceAccountJson'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        setState(() => _fcm = FcmV1Service.fromJson(json));
      }
    } catch (e) {
      debugPrint('loadServiceAccount error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fcm == null) {
      _snack('لم يتم إعداد Service Account بعد', success: false);
      return;
    }

    setState(() => _sending = true);

    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    String status = 'sent';
    String? errorMsg;

    try {
      await _fcm!.sendToTopic(
        topic: 'all_users',
        title: title,
        body: body,
      );
    } catch (e) {
      status = 'error';
      errorMsg = e.toString();
    }

    // سجّل في Firestore بغض النظر عن النتيجة
    try {
      await FirebaseFirestore.instance.collection('broadcasts').add({
        'title': title,
        'body': body,
        'sentBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
        if (errorMsg != null) 'error': errorMsg,
      });
    } catch (_) {}

    if (!mounted) return;
    setState(() => _sending = false);

    if (status == 'sent') {
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _snack('تم إرسال الإشعار بنجاح ✓', success: true);
    } else {
      _snack('فشل الإرسال: $errorMsg', success: false);
    }
  }

  void _snack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperAdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('إشعارات المستخدمين')),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Setup banner ────────────────────────────────
                    if (_fcm == null) ...[
                      _SetupBanner(onRefresh: _loadServiceAccount),
                      const SizedBox(height: 16),
                    ],

                    // ── Compose ─────────────────────────────────────
                    _ComposeCard(
                      formKey: _formKey,
                      titleCtrl: _titleCtrl,
                      bodyCtrl: _bodyCtrl,
                      sending: _sending,
                      enabled: _fcm != null,
                      onSend: _send,
                    ),

                    const SizedBox(height: 28),

                    Text('الإشعارات السابقة',
                        style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    const _BroadcastHistory(),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Setup banner ──────────────────────────────────────────────────────────────

class _SetupBanner extends StatelessWidget {
  final VoidCallback onRefresh;
  const _SetupBanner({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFFE65100), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('إعداد مطلوب مرة واحدة',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: const Color(0xFFE65100))),
              ),
              TextButton(
                onPressed: onRefresh,
                style:
                    TextButton.styleFrom(foregroundColor: Color(0xFFE65100)),
                child: const Text('تحديث'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '1. Firebase Console → Project Settings → Service accounts\n'
            '   → «Generate new private key» → حمّل ملف JSON\n\n'
            '2. Firestore Console → أنشئ مستند:\n'
            '   config  /  fcm_v1\n\n'
            '3. أضف حقل نصي (String):\n'
            '   serviceAccountJson\n'
            '   والصق محتوى ملف JSON كاملاً في القيمة\n\n'
            '4. اضغط «تحديث» أعلاه',
            style: AppTextStyles.body.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ── Compose card ──────────────────────────────────────────────────────────────

class _ComposeCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  const _ComposeCard({
    required this.formKey,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('إشعار جديد', style: AppTextStyles.bodyBold),
                  if (enabled) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success)),
                          const SizedBox(width: 5),
                          Text('جاهز',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              _Field(
                controller: titleCtrl,
                label: 'العنوان',
                hint: 'مثال: تذكير بقراءة حديث اليوم',
                maxLines: 1,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'العنوان مطلوب'
                    : null,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: bodyCtrl,
                label: 'النص',
                hint: 'مثال: لا تنسَ المداومة على السلسلة 🔥',
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'النص مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (sending || !enabled) ? null : onSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    sending ? 'جارٍ الإرسال…' : 'إرسال لجميع المستخدمين',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppTextStyles.caption,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Broadcast history ─────────────────────────────────────────────────────────

class _BroadcastHistory extends StatelessWidget {
  const _BroadcastHistory();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('broadcasts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.notifications_none_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('لا توجد إشعارات مُرسَلة بعد',
                  style: AppTextStyles.caption),
            ]),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final status = d['status'] as String? ?? 'pending';
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null ? _fmt(ts.toDate()) : '…';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(status)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] as String? ?? '',
                              style: AppTextStyles.bodyBold),
                          const SizedBox(height: 4),
                          Text(d['body'] as String? ?? '',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(date, style: AppTextStyles.caption),
                            const SizedBox(width: 10),
                            Text(_statusLabel(status),
                                style: AppTextStyles.caption.copyWith(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static Color _statusColor(String s) => switch (s) {
        'sent' => AppColors.success,
        'error' => AppColors.error,
        _ => AppColors.textMuted,
      };

  static String _statusLabel(String s) => switch (s) {
        'sent' => 'تم الإرسال',
        'error' => 'فشل',
        _ => 'في الانتظار',
      };

  static String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return '${d.day}/${d.month}/${d.year}';
  }
}

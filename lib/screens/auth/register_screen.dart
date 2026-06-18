import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/local_storage_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_feedback.dart';

/// شاشة إنشاء حساب جديد بالبريد الإلكتروني وكلمة المرور.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _strengthLabels = ['ضعيفة جدًا', 'ضعيفة', 'متوسطة', 'قوية', 'قوية جدًا'];
  static const _strengthColors = [
    AppColors.error,
    AppColors.error,
    AppColors.accentDark,
    AppColors.success,
    AppColors.success,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _redirectScheduled = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// إن كان المستخدم مسجَّل الدخول أصلًا يُحوَّل فورًا دون إظهار النموذج.
  void _scheduleRedirectIfSignedIn(SessionService session) {
    if (_redirectScheduled || session.isGuest) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final completedWelcome =
          await session.currentAccountHasCompletedWelcome();
      if (!mounted) return;
      context.go(completedWelcome ? '/home' : '/welcome');
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final session = context.read<SessionService>();
    final error = await session.registerWithEmail(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
    );

    if (!mounted) return;
    if (error == null) {
      await LocalStorageService().savePreferredName(_nameController.text);
    }
    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      final completedWelcome =
          await session.currentAccountHasCompletedWelcome();
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'تم إنشاء حسابك بنجاح 🎉');
      context.go(completedWelcome ? '/home' : '/welcome');
    }
  }

  Widget _buildStrengthMeter() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    final strength = Validators.passwordStrength(_passwordController.text);
    final color = _strengthColors[strength];

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                final filled = i < strength;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 3 ? 0 : 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: filled ? color : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _strengthLabels[strength],
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    _scheduleRedirectIfSignedIn(session);

    if (_redirectScheduled) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/branding/app_logo.png',
                    width: 88,
                    height: 88,
                  ),
                ),
                const SizedBox(height: 16),
                Text('إنشاء حساب جديد', style: AppTextStyles.screenTitle),
                const SizedBox(height: 8),
                Text(
                  'أنشئ حسابًا لحفظ تقدمك وبناء سلسلتك اليومية ومزامنتها.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل اسمك';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    helperText: '6 أحرف على الأقل',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.password,
                ),
                _buildStrengthMeter(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: session.isLoading ? null : _submit,
                    child: session.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('إنشاء الحساب'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('لديك حساب؟ تسجيل الدخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/forgot_password_dialog.dart';

/// شاشة تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _redirectScheduled = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// إن كان المستخدم مسجَّل الدخول أصلًا (مثل وصول مباشر لرابط /login)
  /// يُحوَّل فورًا دون إظهار النموذج.
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
    final error = await session.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      final completedWelcome =
          await session.currentAccountHasCompletedWelcome();
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'مرحبًا بعودتك 👋');
      context.go(completedWelcome ? '/home' : '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    _scheduleRedirectIfSignedIn(session);

    if (_redirectScheduled) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
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
                Text('مرحبًا بعودتك', style: AppTextStyles.screenTitle),
                const SizedBox(height: 8),
                Text(
                  'سجّل دخولك لحفظ تقدمك ومزامنته بين أجهزتك.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 24),
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
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => showForgotPasswordDialog(context),
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
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
                        : const Text('تسجيل الدخول'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('ليس لديك حساب؟ إنشاء حساب جديد'),
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

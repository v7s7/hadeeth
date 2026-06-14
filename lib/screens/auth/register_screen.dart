import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// شاشة إنشاء حساب جديد بالبريد الإلكتروني وكلمة المرور.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
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
    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
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
                    if (value == null || value.trim().isEmpty) return 'أدخل اسمك';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                    if (!value.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    helperText: '6 أحرف على الأقل',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  validator: (value) {
                    if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

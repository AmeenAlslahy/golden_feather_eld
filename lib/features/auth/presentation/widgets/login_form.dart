import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_state_provider.dart';
import '../providers/login_form_provider.dart';
import '../providers/auth_mode_provider.dart';

/// نموذج تسجيل الدخول
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _serverUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(loginFormProvider);
    final notifier = ref.read(authStateProvider.notifier);
    
    final success = await notifier.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      serverUrl: formState.showAdvanced
          ? _serverUrlController.text.trim()
          : null,
    );

    if (success && mounted) {
      context.goNamed('home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // اسم المستخدم
          AppTextField(
            controller: _usernameController,
            label: context.loc.username,
            prefixIcon: const Icon(Icons.person_outline),
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty ? context.loc.usernameRequired : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // كلمة المرور
          AppTextField(
            controller: _passwordController,
            label: context.loc.password,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                formState.obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                ref.read(loginFormProvider.notifier).togglePasswordVisibility();
              },
            ),
            obscureText: formState.obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (v) => v == null || v.isEmpty ? context.loc.passwordRequired : null,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // إعدادات متقدمة
          InkWell(
            onTap: () {
              ref.read(loginFormProvider.notifier).toggleAdvanced();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                  formState.showAdvanced
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(context.loc.advancedLabel),
                ],
              ),
            ),
          ),

          // حقل الخادم
          if (formState.showAdvanced) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _serverUrlController,
              label: context.loc.urlLabel,
              hint: 'https://your-server.com',
              prefixIcon: const Icon(Icons.dns_outlined),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // زر تسجيل الدخول
          AppButton(
            label: context.loc.login,
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: AppSpacing.md),

          // روابط نسيت كلمة المرور وإنشاء حساب
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(authModeProvider.notifier).state = AuthMode.forgotPassword;
                },
                child: Text(
                  context.loc.resetPassword,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authModeProvider.notifier).state = AuthMode.register;
                },
                child: Text(
                  context.loc.registerAction,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




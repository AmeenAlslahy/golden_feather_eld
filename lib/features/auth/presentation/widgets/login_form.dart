import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/value_objects/login_identifier.dart';
import '../../domain/entities/value_objects/password.dart';
import '../providers/auth_mode_provider.dart';
import '../providers/auth_state_provider.dart';
import '../providers/login_form_provider.dart';

/// نموذج تسجيل الدخول
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authStateProvider.notifier);

    await notifier.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    // Navigation is handled automatically by the router listening to auth state
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
          // البريد الإلكتروني أو اسم المستخدم
          AppTextField(
            controller: _usernameController,
            label: context.loc.email,
            prefixIcon: const Icon(Icons.person_outline),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return context.loc.emailRequired;
              }
              final identifierObj = LoginIdentifier(v);
              if (!identifierObj.isValid) {
                return context.translateErrorKey(identifierObj.errorMessage);
              }
              return null;
            },
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
            autofillHints: const [AutofillHints.password],
            validator: (v) {
              if (v == null || v.isEmpty) {
                return context.loc.passwordRequired;
              }
              final passwordObj = Password(v);
              if (!passwordObj.isValid) {
                return context.translateErrorKey(passwordObj.errorMessage);
              }
              return null;
            },
            onSubmitted: (_) => _handleLogin(),
          ),
          
          // نسيت كلمة المرور؟ (إرشاد فقط: الاستعادة تتم عبر المنصة المركزية)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () {
                ref.read(authModeProvider.notifier).state =
                    AuthMode.forgotPassword;
              },
              child: Text(context.loc.resetPassword),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // زر تسجيل الدخول
          AppButton(
            label: context.loc.login,
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleLogin,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_mode_provider.dart';
import '../providers/auth_state_provider.dart';
import 'package:go_router/go_router.dart';

class RegisterFormState {
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  RegisterFormState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  RegisterFormState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return RegisterFormState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  RegisterFormNotifier() : super(RegisterFormState());

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void togglePasswordVisibility() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
  void toggleConfirmPasswordVisibility() => state =
      state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
}

final registerFormProvider =
    StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>(
        (ref) {
  return RegisterFormNotifier();
});

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(registerFormProvider.notifier).setLoading(true);

    final success = await ref.read(authStateProvider.notifier).register(
      name: _fullNameController.text.trim(),
      email: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      ref.read(registerFormProvider.notifier).setLoading(false);
      if (success) {
        context.goNamed('home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registerFormProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الاسم الكامل
          AppTextField(
            controller: _fullNameController,
            label: context.loc.fullName,
            prefixIcon: const Icon(Icons.badge_outlined),
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty
                ? context.loc.fullNameRequired
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // اسم المستخدم
          AppTextField(
            controller: _usernameController,
            label: context.loc.username,
            prefixIcon: const Icon(Icons.person_outline),
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty
                ? context.loc.usernameRequired
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // كلمة المرور
          AppTextField(
            controller: _passwordController,
            label: context.loc.password,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(formState.obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => ref
                  .read(registerFormProvider.notifier)
                  .togglePasswordVisibility(),
            ),
            obscureText: formState.obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.isEmpty ? context.loc.passwordRequired : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // تأكيد كلمة المرور
          AppTextField(
            controller: _confirmPasswordController,
            label: context.loc.confirmPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(formState.obscureConfirmPassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => ref
                  .read(registerFormProvider.notifier)
                  .toggleConfirmPasswordVisibility(),
            ),
            obscureText: formState.obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return context.loc.passwordRequired;
              if (v != _passwordController.text) {
                return context.loc.passwordMismatch;
              }
              return null;
            },
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // زر إنشاء الحساب
          AppButton(
            label: context.loc.registerAction,
            isLoading: formState.isLoading,
            onPressed: formState.isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: AppSpacing.md),

          // العودة لتسجيل الدخول
          TextButton(
            onPressed: () {
              ref.read(authModeProvider.notifier).state = AuthMode.login;
            },
            child: Text(
              '${context.loc.haveAccount} ${context.loc.loginHere}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

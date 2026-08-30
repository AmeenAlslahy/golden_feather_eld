import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_mode_provider.dart';

final forgotPasswordLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class ForgotPasswordForm extends ConsumerStatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  ConsumerState<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(forgotPasswordLoadingProvider.notifier).state = true;

    if (mounted) {
      ref.read(forgotPasswordLoadingProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset is not supported in this version.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(forgotPasswordLoadingProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.loc.resetPassword,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // البريد الإلكتروني
          AppTextField(
            controller: _emailController,
            label: context.loc.email,
            prefixIcon: const Icon(Icons.email_outlined),
            textInputAction: TextInputAction.done,
            validator: (v) => v == null || v.trim().isEmpty
                ? context.loc.emailRequired
                : null,
            onSubmitted: (_) => _handleReset(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // زر الإرسال
          AppButton(
            label: context.loc.sendResetLink,
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleReset,
          ),
          const SizedBox(height: AppSpacing.md),

          // العودة لتسجيل الدخول
          TextButton(
            onPressed: () {
              ref.read(authModeProvider.notifier).state = AuthMode.login;
            },
            child: Text(
              context.loc.backToLogin,
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

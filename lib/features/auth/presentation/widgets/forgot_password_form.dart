import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_mode_provider.dart';

class ForgotPasswordForm extends ConsumerStatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  ConsumerState<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  final _email = TextEditingController();
  bool _sending = false;
  String? _feedback;
  bool _ok = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _ok = false;
        _feedback = _arabic
            ? 'أدخل بريداً صالحاً.'
            : 'Enter a valid email.';
      });
      return;
    }
    setState(() {
      _sending = true;
      _feedback = null;
    });
    final result = await ref.read(authBackendProvider).requestPasswordReset(
          email: email,
          serverUrl: ref.read(localStorageProvider).serverUrl,
        );
    if (!mounted) return;
    result.fold(
      (error) {
        setState(() {
          _sending = false;
          _ok = false;
          _feedback = error is NotFoundError
              ? (_arabic
                  ? 'الاستعادة غير متاحة على هذا الخادم. تواصل مع مدير الأسطول.'
                  : 'Reset is not available on this server. Contact your fleet manager.')
              : anyErrorUserMessage(error, isArabic: _arabic);
        });
      },
      (_) {
        setState(() {
          _sending = false;
          _ok = true;
          _feedback = _arabic
              ? 'إن كان البريد مسجّلاً فستصلك تعليمات إعادة التعيين.'
              : 'If the email is registered, reset instructions will be sent.';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(
          _arabic
              ? 'أدخل بريد الحساب. إن لم يصلك شيء فتواصل مع مدير الأسطول.'
              : 'Enter the account email. If nothing arrives, contact your fleet manager.',
          textAlign: TextAlign.center,
          style: context.styles.muted,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _email,
          label: context.loc.email,
          prefixIcon: const Icon(Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: _arabic ? 'إرسال' : 'Send',
          isLoading: _sending,
          onPressed: _sending ? null : _submit,
        ),
        if (_feedback != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _feedback!,
            textAlign: TextAlign.center,
            style: _ok ? context.styles.success : context.styles.error,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () {
            ref.read(authModeProvider.notifier).state = AuthMode.login;
          },
          child: Text(context.loc.backToLogin),
        ),
      ],
    );
  }
}

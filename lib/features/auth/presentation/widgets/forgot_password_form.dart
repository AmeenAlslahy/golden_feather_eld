import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_mode_provider.dart';

/// نموذج استعادة كلمة المرور — Golden Feather Design System 2.0
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
        _feedback = _arabic ? 'أدخل بريداً صالحاً.' : 'Enter a valid email.';
      });
      return;
    }
    setState(() {
      _sending = true;
      _feedback = null;
    });
    final result = await ref
        .read(authBackendProvider)
        .requestPasswordReset(
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
              : anyErrorUserMessage(error, loc: AppLocalizations.of(context)!);
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
        // عنوان النموذج
        Text(
          context.loc.resetPassword,
          style: context.styles.cardTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        // إرشادات الاستعادة
        Text(
          _arabic
              ? 'أدخل بريد الحساب. إن لم يصلك شيء فتواصل مع مدير الأسطول.'
              : 'Enter the account email. If nothing arrives, contact your fleet manager.',
          textAlign: TextAlign.center,
          style: context.styles.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),

        // حقل إدخال البريد الإلكتروني
        AppTextField(
          controller: _email,
          label: context.loc.email,
          prefixIcon: const Icon(Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.md),

        // زر إرسال الطلب
        AppButton.primary(
          label: _arabic ? 'إرسال' : 'Send',
          isLoading: _sending,
          onPressed: _sending ? null : _submit,
        ),

        // رسالة التغذية الراجعة
        if (_feedback != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.compact,
            ),
            decoration: BoxDecoration(
              color: _ok
                  ? context.goldenColors.successBackground
                  : context.goldenColors.errorBackground,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: _ok
                    ? context.goldenColors.successText.withValues(alpha: 0.25)
                    : context.goldenColors.errorText.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _ok ? Icons.check_circle_outline : Icons.error_outline,
                  color: _ok
                      ? context.goldenColors.successText
                      : context.goldenColors.errorText,
                  size: AppSpacing.iconMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _feedback!,
                    style: _ok ? context.styles.success : context.styles.error,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // زر العودة لتسجيل الدخول
        AppButton.secondary(
          label: context.loc.backToLogin,
          onPressed: () {
            ref.read(authModeProvider.notifier).state = AuthMode.login;
          },
        ),
      ],
    );
  }
}

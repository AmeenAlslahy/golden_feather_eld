import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_mode_provider.dart';

/// إرشاد استعادة كلمة المرور.
///
/// وفق SRS §1 لا ينفّذ التطبيق أي منطق محلي لإعادة التعيين؛ الاستعادة تتم
/// عبر خدمة إعادة التعيين في منصة التتبع المركزية أو بالتواصل مع مدير الأسطول.
class ForgotPasswordForm extends ConsumerWidget {
  const ForgotPasswordForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final colors = Theme.of(context).colorScheme;

    final guidance = isArabic
        ? 'لأسباب أمنية وتنظيمية، لا يمكن إعادة تعيين كلمة المرور من داخل التطبيق.\n\n'
            'يرجى استخدام خدمة استعادة كلمة المرور في منصة التتبع المركزية، '
            'أو التواصل مع مدير الأسطول (Fleet Manager) لإعادة تعيين بيانات الدخول.'
        : 'For security and compliance reasons, passwords cannot be reset from within the app.\n\n'
            'Please use the password recovery service of the central tracking platform, '
            'or contact your Fleet Manager to reset your credentials.';

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
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  guidance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () {
            ref.read(authModeProvider.notifier).state = AuthMode.login;
          },
          child: Text(
            context.loc.backToLogin,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// شريط تنبيه الحالة غير المؤكدة للاتصال بالسيرفر
class SessionUnconfirmedBanner extends StatelessWidget {
  const SessionUnconfirmedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: context.warningContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: context.warning.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: context.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.sessionStatusUnconfirmed,
                    key: const Key('session_unconfirmed_banner'),
                    style: context.styles.body.copyWith(
                      color: context.warning,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.loc.sessionStatusUnconfirmedHint,
                    style: context.styles.body.copyWith(
                      color: context.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط تنبيه عند فشل الاتصال بجهاز الـ ELD
class ConnectionFailureBanner extends StatelessWidget {
  final String message;

  const ConnectionFailureBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: context.dangerContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: context.danger.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: context.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.styles.body.copyWith(
                  color: context.danger,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

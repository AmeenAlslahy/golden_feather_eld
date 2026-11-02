import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// واجهة موحدة لحالات الخطأ والفراغ (Design System 2.0).
///
/// تدعم نمطين دلاليين:
/// 1. حالة الخطأ (Error State): رسالة وأيقونة وإجراء إعادة المحاولة عندما يكون متاحاً.
/// 2. حالة الفراغ (Empty State): رسالة وأيقونة مناسبة دون فرض زر إعادة المحاولة.
class EldRetryView extends StatelessWidget {
  const EldRetryView({
    super.key,
    required this.message,
    this.onRetry,
    this.isError = true,
    this.title,
    this.icon,
  });

  /// مُنشئ دلالي لحالات الخطأ
  const EldRetryView.error({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
  }) : isError = true;

  /// مُنشئ دلالي لحالات الفراغ
  const EldRetryView.empty({
    super.key,
    required this.message,
    this.title,
    VoidCallback? onAction,
    this.icon,
  })  : isError = false,
        onRetry = onAction;

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final bool isError;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goldenColors = context.goldenColors;

    final effectiveIcon =
        icon ?? (isError ? Icons.error_outline : Icons.inbox_outlined);
    final iconColor = isError ? goldenColors.errorText : goldenColors.textMuted;
    final titleColor = isError ? goldenColors.errorText : theme.colorScheme.onSurface;
    final messageStyle = isError
        ? context.styles.error
        : context.styles.body.copyWith(color: goldenColors.textMuted);

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.emptyStateMaxWidth,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              effectiveIcon,
              size: AppSizing.logoSmall,
              color: iconColor,
            ),
            const SizedBox(height: AppSpacing.md),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: context.styles.cardTitle.copyWith(
                  color: titleColor,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: messageStyle,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              IconButton(
                tooltip:
                    AppLocalizations.of(context)?.retryButton ?? 'Retry',
                iconSize: AppSpacing.iconHero,
                color: goldenColors.primaryText,
                onPressed: onRetry,
                icon: Icon(Icons.refresh, color: goldenColors.primaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

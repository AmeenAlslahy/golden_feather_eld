import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// الأنواع الدلالية للحوارات (AppDialog)
enum AppDialogType {
  /// حوار معلوماتي أحادي الإجراء (معلومات/إشعار)
  informational,

  /// حوار تأكيد ثنائي الإجراء (تأكيد/إلغاء)
  confirmation,

  /// حوار إجراء حرج أو حذف (حذف/تراجع)
  destructive,
}

/// مكوّن حوار موحد للتطبيق (Design System 2.0).
///
/// يدعم الحالات المعلوماتية والتأكيدية والحرجة مع توافق كامل مع Light وDark
/// وRTL/LTR ومرونة تكبير النصوص دون حدوث Overflow.
class AppDialog extends StatelessWidget {
  final String title;
  final String? contentText;
  final Widget? contentWidget;
  final IconData? icon;
  final AppDialogType type;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? destructiveActionLabel;
  final VoidCallback? onDestructiveAction;

  const AppDialog({
    super.key,
    required this.title,
    this.contentText,
    this.contentWidget,
    this.icon,
    this.type = AppDialogType.confirmation,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.destructiveActionLabel,
    this.onDestructiveAction,
  });

  /// مُنشئ سريع لحوار معلوماتي
  const AppDialog.informational({
    super.key,
    required this.title,
    this.contentText,
    this.contentWidget,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
  })  : type = AppDialogType.informational,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        destructiveActionLabel = null,
        onDestructiveAction = null;

  /// مُنشئ سريع لحوار تأكيد
  const AppDialog.confirmation({
    super.key,
    required this.title,
    this.contentText,
    this.contentWidget,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : type = AppDialogType.confirmation,
        destructiveActionLabel = null,
        onDestructiveAction = null;

  /// مُنشئ سريع لحوار حذف أو إجراء حرج
  const AppDialog.destructive({
    super.key,
    required this.title,
    this.contentText,
    this.contentWidget,
    this.icon,
    this.destructiveActionLabel,
    this.onDestructiveAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : type = AppDialogType.destructive,
        primaryActionLabel = null,
        onPrimaryAction = null;

  /// دالة مساعدة لفتح الحوار وإرجاع نتيجة بوليانية
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? contentText,
    Widget? contentWidget,
    IconData? icon,
    AppDialogType type = AppDialogType.confirmation,
    String? primaryLabel,
    String? secondaryLabel,
    String? destructiveLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: title,
        contentText: contentText,
        contentWidget: contentWidget,
        icon: icon,
        type: type,
        primaryActionLabel: primaryLabel,
        onPrimaryAction: () => Navigator.of(dialogContext).pop(true),
        secondaryActionLabel: secondaryLabel,
        onSecondaryAction: () => Navigator.of(dialogContext).pop(false),
        destructiveActionLabel: destructiveLabel,
        onDestructiveAction: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goldenColors = context.goldenColors;

    final (IconData defaultIcon, Color iconColor, Color iconBg) = switch (type) {
      AppDialogType.destructive => (
        Icons.warning_amber_rounded,
        goldenColors.errorText,
        goldenColors.errorBackground,
      ),
      AppDialogType.confirmation => (
        Icons.help_outline_rounded,
        goldenColors.primaryText,
        goldenColors.surfaceSecondary,
      ),
      AppDialogType.informational => (
        Icons.info_outline_rounded,
        goldenColors.infoText,
        goldenColors.infoBackground,
      ),
    };

    final effectiveIcon = icon ?? defaultIcon;

    final backgroundColor = isDark
        ? goldenColors.surfaceElevated
        : theme.colorScheme.surface;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
        side: BorderSide(
          color: goldenColors.border,
          width: isDark ? 1.0 : 0.5,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.emptyStateMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── أيقونة رأس الحوار الدلالية ───
              Center(
                child: Container(
                  width: AppSizing.iconLarge * 1.5,
                  height: AppSizing.iconLarge * 1.5,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    effectiveIcon,
                    size: AppSizing.iconStandard,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── العنوان ───
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.styles.cardTitle.copyWith(
                  fontSize: 18,
                  fontWeight: AppTypography.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ─── المحتوى ───
              if (contentWidget != null)
                contentWidget!
              else if (contentText != null)
                Text(
                  contentText!,
                  textAlign: TextAlign.center,
                  style: context.styles.body.copyWith(
                    color: goldenColors.textMuted,
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // ─── أزرار الإجراءات ───
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final matLoc = MaterialLocalizations.of(context);
    final effectivePrimaryLabel = primaryActionLabel ?? matLoc.okButtonLabel;
    final effectiveSecondaryLabel =
        secondaryActionLabel ?? matLoc.cancelButtonLabel;
    final effectiveDestructiveLabel =
        destructiveActionLabel ?? matLoc.deleteButtonTooltip;

    if (type == AppDialogType.informational) {
      return AppButton.primary(
        label: effectivePrimaryLabel,
        onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(true),
      );
    }

    final isLargeText = MediaQuery.textScalerOf(context).scale(14) >= 20;

    if (isLargeText) {
      if (type == AppDialogType.destructive) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton.destructive(
              label: effectiveDestructiveLabel,
              onPressed:
                  onDestructiveAction ?? () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: effectiveSecondaryLabel,
              onPressed:
                  onSecondaryAction ?? () => Navigator.of(context).pop(false),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.primary(
            label: effectivePrimaryLabel,
            onPressed:
                onPrimaryAction ?? () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: effectiveSecondaryLabel,
            onPressed:
                onSecondaryAction ?? () => Navigator.of(context).pop(false),
          ),
        ],
      );
    }

    if (type == AppDialogType.destructive) {
      return Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              label: effectiveSecondaryLabel,
              onPressed:
                  onSecondaryAction ?? () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton.destructive(
              label: effectiveDestructiveLabel,
              onPressed:
                  onDestructiveAction ?? () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      );
    }

    // Confirmation
    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            label: effectiveSecondaryLabel,
            onPressed:
                onSecondaryAction ?? () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton.primary(
            label: effectivePrimaryLabel,
            onPressed:
                onPrimaryAction ?? () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
  }
}

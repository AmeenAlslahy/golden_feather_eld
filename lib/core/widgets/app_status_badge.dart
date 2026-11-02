import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/golden_colors.dart';
import 'status_color_resolver.dart';

/// الحالات الدلالية للشارات في التطبيق
enum AppStatusBadgeType {
  success,
  error,
  warning,
  info,
  neutral;

  /// ربط الحالة بالدور الدلالي الموحد
  StatusSemanticRole get role => switch (this) {
    AppStatusBadgeType.success => StatusSemanticRole.success,
    AppStatusBadgeType.error => StatusSemanticRole.error,
    AppStatusBadgeType.warning => StatusSemanticRole.warning,
    AppStatusBadgeType.info => StatusSemanticRole.info,
    AppStatusBadgeType.neutral => StatusSemanticRole.neutral,
  };
}

/// شارة حالة موحدة للتطبيق تستمد ألوانها من [GoldenColors] عبر [StatusSemanticRole]
/// وخطوطها من [AppStyles.badge] وزواياها من [AppRadius.badge].
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusBadgeType type;
  final IconData? icon;
  final Widget? trailing;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goldenColors =
        theme.extension<GoldenColors>() ??
        (theme.brightness == Brightness.dark
            ? GoldenColors.dark
            : GoldenColors.light);

    final (textColor, backgroundColor) = type.role.resolve(goldenColors);

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.badge),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.space2,
            children: [
              if (icon != null)
                Icon(icon, size: AppSpacing.iconSmallBadge, color: textColor),
              Text(
                label,
                style: context.styles.badge.copyWith(
                  color: textColor,
                  fontWeight: AppTypography.bold,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

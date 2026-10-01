import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/eld_colors.dart';
import '../theme/app_typography.dart';

enum AppStatusBadgeType {
  success,
  error,
  warning,
  info,
}

/// شارة حالة موحدة للتطبيق
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

  Color _getBackgroundColor(ThemeData theme) {
    final eld = theme.extension<EldColors>()!;
    switch (type) {
      case AppStatusBadgeType.success:
        return eld.successBg;
      case AppStatusBadgeType.error:
        return eld.dangerBg;
      case AppStatusBadgeType.warning:
        return eld.warningBg;
      case AppStatusBadgeType.info:
        return eld.infoBg;
    }
  }

  Color _getTextColor(ThemeData theme) {
    final eld = theme.extension<EldColors>()!;
    switch (type) {
      case AppStatusBadgeType.success:
        return eld.successFg;
      case AppStatusBadgeType.error:
        return eld.dangerFg;
      case AppStatusBadgeType.warning:
        return AppColors.warningYellow;
      case AppStatusBadgeType.info:
        // Gold on the pale info background is ~2.5:1; infoText is 8.6:1.
        return AppColors.infoText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = _getTextColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: AppTypography.bold,
            ).copyWith(color: textColor),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

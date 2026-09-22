import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_gap.dart';

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

  Color _getBackgroundColor(BuildContext context) {
    final eld = context.eld;
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

  Color _getTextColor() {
    switch (type) {
      case AppStatusBadgeType.success:
        return AppColors.successGreen;
      case AppStatusBadgeType.error:
        return AppColors.dangerRed;
      case AppStatusBadgeType.warning:
        return AppColors.warningYellow;
      case AppStatusBadgeType.info:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            AppGap.hXs,
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: AppTypography.bold,
            ).copyWith(color: textColor),
          ),
          if (trailing != null) ...[
            AppGap.hXs,
            trailing!,
          ],
        ],
      ),
    );
  }
}
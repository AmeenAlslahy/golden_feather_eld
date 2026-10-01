import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppStatusBadgeType {
  success,
  error,
  warning,
  info,
}

/// شارة حالة موحدة للتطبيق
///
/// الألوان من `AppColors` حصرياً: مجموعة النص/الخلفية الفاتحة في الوضع
/// الفاتح، ومجموعة `OnDark`/`dark*Bg` في الداكن — أزواج مضمونة التباين.
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

  Color _getBackgroundColor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (type) {
      case AppStatusBadgeType.success:
        return isDark ? AppColors.darkSuccessBg : AppColors.successBg;
      case AppStatusBadgeType.error:
        return isDark ? AppColors.darkDangerBg : AppColors.dangerBg;
      case AppStatusBadgeType.warning:
        return isDark ? AppColors.darkWarningBg : AppColors.warningBg;
      case AppStatusBadgeType.info:
        return isDark ? AppColors.darkInfoBg : AppColors.infoBg;
    }
  }

  Color _getTextColor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (type) {
      case AppStatusBadgeType.success:
        return isDark ? AppColors.successOnDark : AppColors.successText;
      case AppStatusBadgeType.error:
        return isDark ? AppColors.dangerOnDark : AppColors.dangerText;
      case AppStatusBadgeType.warning:
        return isDark ? AppColors.warningOnDark : AppColors.warningText;
      case AppStatusBadgeType.info:
        return isDark ? AppColors.infoOnDark : AppColors.infoText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor = _getTextColor(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(brightness),
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

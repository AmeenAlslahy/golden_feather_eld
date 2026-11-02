import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_decorations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/golden_colors.dart';
import 'status_color_resolver.dart';

/// الحالات الدلالية للشارات الدائرية (Pills) في التطبيق
enum AppStatusPillType {
  success,
  error,
  warning,
  info,
  neutral;

  /// ربط الحالة بالدور الدلالي الموحد
  StatusSemanticRole get role => switch (this) {
    AppStatusPillType.success => StatusSemanticRole.success,
    AppStatusPillType.error => StatusSemanticRole.error,
    AppStatusPillType.warning => StatusSemanticRole.warning,
    AppStatusPillType.info => StatusSemanticRole.info,
    AppStatusPillType.neutral => StatusSemanticRole.neutral,
  };
}

/// شارة حالة صغيرة دائرية (Pill): أيقونة اختيارية + نص داخل حاوية ملوّنة.
///
/// تدعم الحالات الدلالية الموحدة المشتقة من [GoldenColors] عبر [StatusSemanticRole] مع الحفاظ الكامل
/// على التوافق مع الاستخدامات السابقة التي تمرر [color] مباشرة.
class AppStatusPill extends StatelessWidget {
  final IconData? icon;
  final double iconSize;
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final AppStatusPillType? type;

  /// مُنشئ التوافق الخلفي بتمرير لون مخصص مباشرة
  const AppStatusPill({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
    required Color this.color,
    this.backgroundColor,
  }) : type = null;

  /// مُنشئ دلالي لحالة النجاح
  const AppStatusPill.success({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
  })  : color = null,
        backgroundColor = null,
        type = AppStatusPillType.success;

  /// مُنشئ دلالي لحالة الخطأ
  const AppStatusPill.error({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
  })  : color = null,
        backgroundColor = null,
        type = AppStatusPillType.error;

  /// مُنشئ دلالي لحالة التحذير
  const AppStatusPill.warning({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
  })  : color = null,
        backgroundColor = null,
        type = AppStatusPillType.warning;

  /// مُنشئ دلالي لحالة المعلومات
  const AppStatusPill.info({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
  })  : color = null,
        backgroundColor = null,
        type = AppStatusPillType.info;

  /// مُنشئ دلالي للحالة الحيادية
  const AppStatusPill.neutral({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
  })  : color = null,
        backgroundColor = null,
        type = AppStatusPillType.neutral;

  (Color, Color) _resolveColors(BuildContext context) {
    if (type != null) {
      return type!.role.resolve(context.goldenColors);
    }

    final textColor = color ?? context.goldenColors.primaryText;
    final bgColor = backgroundColor ??
        AppDecorations.tinted(textColor).color ??
        textColor.withValues(alpha: 0.12);
    return (textColor, bgColor);
  }

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor) = _resolveColors(context);

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
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: textColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: context.styles.badge.copyWith(
                    color: textColor,
                    fontWeight: AppTypography.semiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

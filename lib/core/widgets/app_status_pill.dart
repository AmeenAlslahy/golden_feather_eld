import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_decorations.dart';
import '../theme/app_spacing.dart';

/// شارة حالة صغيرة: نقطة/أيقونة + نص داخل حاوية ملوّنة شفافة.
///
/// مرّر لون **المقدمة** من زوج التباين الصحيح
/// (`context.styles.success.color!` / `error` / `warning` …)، وتُشتق
/// خلفية الشارة منه بشفافية الهوية — فلا يُختار لوناً خاماً في الشاشة.
class AppStatusPill extends StatelessWidget {
  final IconData? icon;
  final double iconSize;
  final String label;
  final Color color;

  const AppStatusPill({
    super.key,
    this.icon,
    this.iconSize = 8.0,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecorations.tinted(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: context.styles.caption.copyWith(
              color: color,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

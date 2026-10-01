import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
        vertical: 4,
      ),
      decoration: AppDecorations.tinted(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
// import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// صف معلومات - عنوان رمادي على اليسار، قيمة سوداء على اليمين
class EldInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const EldInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // العنوان - رمادي
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.bodySize,
                fontWeight: AppTypography.regular,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            // القيمة - أسود Bold
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: AppTypography.largeButtonSize,
                  fontWeight: AppTypography.bold,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';

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
      splashColor: Colors.black.withValues(alpha: 0.12),
      highlightColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // العنوان - رمادي
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: context.styles.body.copyWith(
                  color: context.styles.subtitle.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // القيمة - أسود
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.start,
                style: valueColor == null
                    ? context.styles.body
                    : context.styles.body.copyWith(color: valueColor),
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

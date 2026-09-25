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
            // العنوان - رمادي (يلتف بدل أن يفيض مع العناوين الطويلة)
            Flexible(
              child: Text(
                label,
                style: context.styles.muted,
              ),
            ),
            const SizedBox(width: 16),
            // القيمة - أسود Bold
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: valueColor == null
                    ? context.styles.bodyBold
                    : context.styles.bodyBold.copyWith(color: valueColor),
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

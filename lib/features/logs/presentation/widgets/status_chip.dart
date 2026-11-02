import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';

/// نغمة شريحة الحالة. الافتراضي (عند غياب [StatusChip.tone]) يبقى
/// success/error المألوف كي لا تتغير بقية الشاشات.
enum StatusChipTone { success, error, pending, warning }

/// شريحة حالة (Form/Cert)
class StatusChip extends StatelessWidget {
  final String label;
  final bool isComplete;
  final StatusChipTone? tone;

  const StatusChip({
    super.key,
    required this.label,
    required this.isComplete,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTone =
        tone ?? (isComplete ? StatusChipTone.success : StatusChipTone.error);
    final (
      IconData icon,
      Color color,
      TextStyle style,
    ) = switch (effectiveTone) {
      StatusChipTone.success => (
        Icons.check_circle,
        context.success,
        context.styles.success,
      ),
      StatusChipTone.error => (
        Icons.cancel,
        context.danger,
        context.styles.error,
      ),
      StatusChipTone.pending => (
        Icons.schedule,
        context.warning,
        context.styles.warning,
      ),
      StatusChipTone.warning => (
        Icons.error_outline,
        context.warning,
        context.styles.warning,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: AppSpacing.iconMedium),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(fontWeight: AppTypography.semiBold),
          ),
        ),
      ],
    );
  }
}

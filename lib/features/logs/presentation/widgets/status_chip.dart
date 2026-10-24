import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';

/// شريحة حالة (Form/Cert)
class StatusChip extends StatelessWidget {
  final String label;
  final bool isComplete;

  const StatusChip({super.key, required this.label, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.cancel,
          color: isComplete ? context.success : context.danger,
          size: AppSpacing.iconMedium,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (isComplete ? context.styles.success : context.styles.error)
                .copyWith(fontWeight: AppTypography.semiBold),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class RuleSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const RuleSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.rowHorizontal,
        vertical: AppSpacing.rowVertical,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.styles.body.copyWith(
                color: context.textSecondary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}

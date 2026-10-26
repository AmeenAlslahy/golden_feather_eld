import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class RuleSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dense;

  const RuleSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = dense
        ? AppTypography.subtitleSize
        : AppTypography.bodySize;
    final verticalPadding = dense
        ? AppSpacing.rowVerticalCompact
        : AppSpacing.rowVertical;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.rowHorizontal,
        vertical: verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.styles.subtitle.copyWith(
                fontSize: fontSize,
                color: context.textSecondary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class StatusOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLast;
  final bool enabled;
  final VoidCallback? onTap;

  const StatusOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isLast,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedRadioColor = theme.disabledColor.withValues(alpha: 0.5);
    
    final isClickable = enabled && onTap != null;

    return Column(
      children: [
        InkWell(
          onTap: isClickable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: !enabled
                          ? theme.disabledColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? primaryColor : unselectedRadioColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }
}




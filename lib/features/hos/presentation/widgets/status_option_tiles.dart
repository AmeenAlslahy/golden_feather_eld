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
    const primaryBlue = Color(0xFF0B60B0);
    const unselectedRadioColor = Color(0xFFDCDCDC);
    const dividerColor = Color(0xFFEEEEEE);
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
                    style: TextStyle(
                      fontSize: 16,
                      color: !enabled
                          ? Colors.black26
                          : Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? primaryBlue : unselectedRadioColor,
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
            color: dividerColor,
          ),
      ],
    );
  }
}



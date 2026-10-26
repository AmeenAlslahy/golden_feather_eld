import 'package:flutter/material.dart';

import '../../../../../core/widgets/eld_dropdown_row.dart';

class RuleDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool dense;

  const RuleDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    return EldDropdownRow(
      label: label,
      value: value,
      items: options,
      dense: dense,
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
}

import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/theme/app_typography.dart';
// import '../../../../core/widgets/app_button.dart';

/// نموذج سائق مساعد
class CoDriver {
  final String id;
  final String name;

  const CoDriver({required this.id, required this.name});
}

/// Dialog اختيار السائق المساعد
class CoDriverPickerDialog extends StatefulWidget {
  final String? currentCoDriverId;

  const CoDriverPickerDialog({super.key, this.currentCoDriverId});

  @override
  State<CoDriverPickerDialog> createState() => _CoDriverPickerDialogState();
}

class _CoDriverPickerDialogState extends State<CoDriverPickerDialog> {
  String? _selectedId;

  // بيانات وهمية للسائقين المساعدين
  final List<CoDriver> _codrivers = const [
    CoDriver(id: 'none', name: 'No One'),
    CoDriver(id: 'co1', name: 'Mohamed Ahmed'),
    CoDriver(id: 'co2', name: 'Ali Hassan'),
    CoDriver(id: 'co3', name: 'Omar Khalid'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentCoDriverId ?? 'none';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.coDriver),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _codrivers.map((driver) {
            final isSelected = driver.id == _selectedId;
            return RadioListTile<String>(
              title: Text(
                driver.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              value: driver.id,
              groupValue: _selectedId,
              onChanged: (value) {
                setState(() => _selectedId = value);
              },
              activeColor: AppColors.primaryBlue,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final selected = _codrivers.firstWhere(
              (d) => d.id == _selectedId,
              orElse: () => _codrivers.first,
            );
            Navigator.pop(context, selected);
          },
          child: Text(context.loc.okButton),
        ),
      ],
    );
  }
}

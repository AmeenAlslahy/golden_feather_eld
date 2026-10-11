import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';

/// حوار تصفية أحداث المعاينة (الكل / النشطة فقط)
class InspectionFilterDialog extends StatefulWidget {
  final bool initialShowActiveOnly;

  const InspectionFilterDialog({
    super.key,
    required this.initialShowActiveOnly,
  });

  @override
  State<InspectionFilterDialog> createState() => _InspectionFilterDialogState();
}

class _InspectionFilterDialogState extends State<InspectionFilterDialog> {
  late bool _showActive;

  @override
  void initState() {
    super.initState();
    _showActive = widget.initialShowActiveOnly;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.loc.filter,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: RadioGroup<bool>(
        groupValue: _showActive,
        onChanged: (val) {
          if (val != null) {
            setState(() => _showActive = val);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: Text(context.loc.allEvents),
              value: false,
            ),
            RadioListTile<bool>(
              title: Text(context.loc.activeEvents),
              value: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(context.loc.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _showActive),
          child: Text(context.loc.okButton),
        ),
      ],
    );
  }
}

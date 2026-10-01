import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';


class DvirStatusModal extends StatelessWidget {
  final bool hasDefect;
  final String? selectedStatus;

  const DvirStatusModal({
    super.key,
    required this.hasDefect,
    this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AlertDialog(
      title: Text(loc.status),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(loc.dvirSatisfactory),
            enabled: !hasDefect,
            subtitle: hasDefect ? Text(loc.dvirDefectRecorded) : null,
            onTap: hasDefect
                ? null
                : () => Navigator.pop(
                      context,
                      'Vehicle Condition Satisfactory',
                    ),
          ),
          ListTile(
            title: Text(loc.dvirHasDefects),
            onTap: () => Navigator.pop(context, 'Has Defects'),
          ),
          ListTile(
            enabled: false,
            title: Text(loc.dvirDefectsCorrected),
            subtitle: Text(loc.dvirNoRepairCert),
          ),
          ListTile(
            enabled: false,
            title: Text(loc.dvirDefectsNotCorrected),
            subtitle: Text(loc.dvirSetByCarrier),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedStatus),
          child: Text(loc.okButton),
        ),
      ],
    );
  }
}

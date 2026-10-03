import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/dvir_report.dart';

/// اختيار حالة DVIR الرسمية — يُرجع [DvirConditionStatus]، لا نصوص wire.
class DvirStatusModal extends StatelessWidget {
  final bool hasDefect;
  final DvirConditionStatus? selectedStatus;

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
                      DvirConditionStatus.satisfactory,
                    ),
          ),
          ListTile(
            title: Text(loc.dvirHasDefects),
            onTap: () => Navigator.pop(context, DvirConditionStatus.hasDefects),
          ),
          // حالتا الإصلاح يضبطهما الناقل بعد شهادة الإصلاح — ليست قراراً
          // للسائق هنا (SRS 7.6).
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

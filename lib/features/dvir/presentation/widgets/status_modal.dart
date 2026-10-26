import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/dvir_report.dart';
import '../extensions/dvir_status_extensions.dart';

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
      backgroundColor: context.colorScheme.surface,
      // العنوان بلا نمط صريح ⇒ افتراضي dialogTheme (20) — مثل كل حوارات
      // التطبيق؛ كان هنا sectionTitle (16) فحده بين 15 حواراً.
      title: Text(loc.status),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                DvirConditionStatus.satisfactory.label(loc),
                style: context.styles.body,
              ),
              selected: selectedStatus == DvirConditionStatus.satisfactory,
              trailing: selectedStatus == DvirConditionStatus.satisfactory
                  ? Icon(Icons.check, color: context.colorScheme.primary)
                  : null,
              // القاعدة (من يجوز له اختيار ما) في النطاق؛ الحوار يعرضها.
              enabled: DvirConditionStatus.satisfactory.driverMaySelect(
                hasDefects: hasDefect,
              ),
              subtitle: hasDefect
                  ? Text(loc.dvirDefectRecorded, style: context.styles.subtitle)
                  : null,
              onTap:
                  DvirConditionStatus.satisfactory.driverMaySelect(
                    hasDefects: hasDefect,
                  )
                  ? () =>
                        Navigator.pop(context, DvirConditionStatus.satisfactory)
                  : null,
            ),
            ListTile(
              title: Text(
                DvirConditionStatus.hasDefects.label(loc),
                style: context.styles.body,
              ),
              selected: selectedStatus == DvirConditionStatus.hasDefects,
              trailing: selectedStatus == DvirConditionStatus.hasDefects
                  ? Icon(Icons.check, color: context.colorScheme.primary)
                  : null,
              onTap: () =>
                  Navigator.pop(context, DvirConditionStatus.hasDefects),
            ),
            // حالتا الإصلاح يضبطهما الناقل بعد شهادة الإصلاح — ليست قراراً
            // للسائق هنا (SRS 7.6).
            ListTile(
              enabled: DvirConditionStatus.defectsCorrected.driverMaySelect(
                hasDefects: hasDefect,
              ),
              title: Text(
                DvirConditionStatus.defectsCorrected.label(loc),
                style: context.styles.body,
              ),
              subtitle: Text(
                loc.dvirNoRepairCert,
                style: context.styles.subtitle,
              ),
            ),
            ListTile(
              enabled: DvirConditionStatus.defectsNotCorrected.driverMaySelect(
                hasDefects: hasDefect,
              ),
              title: Text(
                DvirConditionStatus.defectsNotCorrected.label(loc),
                style: context.styles.body,
              ),
              subtitle: Text(
                loc.dvirSetByCarrier,
                style: context.styles.subtitle,
              ),
            ),
          ],
        ),
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

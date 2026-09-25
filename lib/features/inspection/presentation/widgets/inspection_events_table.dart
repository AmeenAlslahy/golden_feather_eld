import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/inspection/dot_inspection.dart';

/// Read-only event list for roadside inspection (typed DOT events).
class InspectionEventsTable extends StatelessWidget {
  const InspectionEventsTable({super.key, required this.events});

  final List<DotInspectionEvent> events;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            context.loc.noData,
            style: context.styles.muted,
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  isArabic ? 'الوقت' : 'Time',
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  isArabic ? 'الحالة' : 'Status',
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  isArabic ? 'الموقع' : 'Location',
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  isArabic ? 'عداد' : 'Odom',
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  isArabic ? 'محرك' : 'Eng',
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        ...events.map((event) => _EventRow(event: event)),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final DotInspectionEvent event;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = event.description.isNotEmpty
        ? event.description
        : (event.eventCode.isNotEmpty ? event.eventCode : event.eventType);
    final statusLabel = event.certificationEvent
        ? (isArabic ? 'اعتماد · $status' : 'Cert · $status')
        : status;
    final extras = <String>[
      if (event.origin.trim().isNotEmpty)
        isArabic ? 'المصدر: ${event.origin}' : 'Origin: ${event.origin}',
      if (event.notes.trim().isNotEmpty)
        isArabic ? 'ملاحظات: ${event.notes}' : 'Notes: ${event.notes}',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(event.timeEt, style: context.styles.caption),
              ),
              Expanded(
                flex: 2,
                child: Text(statusLabel, style: context.styles.body),
              ),
              Expanded(
                flex: 3,
                child: Text(event.location, style: context.styles.caption),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  event.odometer.toStringAsFixed(0),
                  style: context.styles.caption,
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  event.engineHours.toStringAsFixed(1),
                  style: context.styles.caption,
                ),
              ),
            ],
          ),
          if (extras.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 56),
              child: Text(
                extras.join(' · '),
                style: context.styles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

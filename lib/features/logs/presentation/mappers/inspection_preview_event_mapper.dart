import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/status_color_helper.dart';
import '../../../../core/widgets/eld_events_table.dart';
import '../../domain/entities/daily_log.dart';

/// Maps domain [LogEvent] entities into presentation [EldTableRow]s for the
/// FMCSA 49 CFR §395.8 RODS roadside inspection preview table.
class InspectionPreviewEventMapper {
  const InspectionPreviewEventMapper._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats event timestamp into official roadside format: `Mmm dd, hh:mm:ss am/pm`.
  static String formatEventTime(DateTime dt) {
    final m = _months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hStr = hour12.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'pm' : 'am';
    return '$m $day, $hStr:$min:$sec $period';
  }

  /// Maps duty status codes to standard roadside English terms or localized fallbacks.
  static String formatEventStatus(String status, BuildContext context) {
    switch (status.toUpperCase()) {
      case 'OFF':
        return 'Off Duty';
      case 'SB':
        return 'Sleeper';
      case 'D':
        return 'Driving';
      case 'ON':
        return 'On Duty';
      case 'PC':
        return 'Personal Conveyance';
      case 'YM':
        return 'Yard Move';
      default:
        return context.translateStatus(status);
    }
  }

  /// Converts a [LogEvent] to an [EldTableRow] for the inspection table.
  static EldTableRow toTableRow(LogEvent event, BuildContext context) {
    final srcLabel = event.automatedDriving == null
        ? '—'
        : event.automatedDriving!
        ? 'Auto'
        : 'Driver';

    return EldTableRow(
      time: formatEventTime(event.startTime),
      status: formatEventStatus(event.status, context),
      location: event.location,
      odom: event.odometer != null ? event.odometer!.toStringAsFixed(0) : '-',
      eng: event.engineHours != null
          ? event.engineHours!.toStringAsFixed(1)
          : '-',
      src: srcLabel,
      notes: null,
      statusColor: StatusColorHelper.getStatusColor(event.status),
    );
  }

  /// Filters events to display only active duty status events when requested.
  static List<LogEvent> filterEvents(
    List<LogEvent> events, {
    required bool showActiveOnly,
  }) {
    if (!showActiveOnly) return events;
    const activeStatuses = {'ON', 'D', 'SB', 'OFF', 'PC', 'YM'};
    return events.where((e) => activeStatuses.contains(e.status)).toList();
  }
}

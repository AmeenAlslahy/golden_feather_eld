import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import '../../domain/entities/daily_log.dart';

/// تنسيق عرض تاريخ السجل — مسؤولية العرض لا الكيان.
///
/// الكيان [DailyLog] يبقى بيانات خالصة؛ هذه الدوال تحافظ على التوافق
/// مع الاستدعاءات الحالية وتوفر تنسيقاً محلياً واعياً باللغة.
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
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

String _ordinal(int day) {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

String logDayName(DailyLog log) =>
    log.today ? 'Today' : _weekdays[log.date.weekday - 1];

String formatLogDate(DailyLog log) =>
    '${logDayName(log)} - ${_months[log.date.month - 1]} ${log.date.day}'
    '${_ordinal(log.date.day)}';

/// تنسيق محلي واعي باللغة يدعم العربية والإنجليزية والإسبانية (Phase 5C).
String formatLocalizedDailyLogDate(BuildContext context, DailyLog log) {
  final matLoc = MaterialLocalizations.of(context);
  final mediumDate = matLoc.formatMediumDate(log.date);
  if (log.today) {
    return context.loc.todayLogDate(mediumDate);
  }
  return matLoc.formatFullDate(log.date);
}

/// اختصار للاستخدام في الواجهات: `log.formattedDate` للتوافق،
/// و `log.localizedDate(context)` للعرض المحلي الدقيق.
extension DailyLogDateFormatting on DailyLog {
  String get dayName => logDayName(this);
  String get formattedDate => formatLogDate(this);
  String localizedDate(BuildContext context) =>
      formatLocalizedDailyLogDate(context, this);
}


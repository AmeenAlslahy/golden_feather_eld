import 'entities/daily_log.dart';

/// الجزء الظاهر من حدث داخل يوم السجل (0..24 ساعة).
///
/// الرسم والإجماليات يستهلكان نفس القطع، فلا يعرض الرسم ساعتين بينما
/// يجمع صف الإجماليات ثماني ساعات لحدث بدأ في اليوم السابق.
class LogEventDaySlice {
  /// بداية الجزء بالساعات من منتصف ليل يوم السجل.
  final double startHour;

  /// نهاية الجزء بالساعات من منتصف ليل يوم السجل.
  final double endHour;

  /// مدة الجزء الظاهر بالدقائق — نفس الأساس الذي يرسمه المخطط.
  final Duration visibleDuration;

  const LogEventDaySlice({
    required this.startHour,
    required this.endHour,
    required this.visibleDuration,
  });
}

const int _minutesPerDay = 24 * 60;

/// يقص [event] على حدود يوم السجل [logDate].
///
/// يعيد null إذا كان الحدث خارج اليوم أو مدته صفر. الحدث الذي يبدأ قبل
/// منتصف الليل أو ينتهي بعده يُحسب منه الجزء الواقع داخل اليوم فقط.
///
/// ⚠️ يستخدم توقيت الجهاز المحلي كما كان الرسم السابق يفعل. لا يفترض أن
/// هذا هو توقيت السجل المعتمد من الخادم؛ تغيير قاعدة المنطقة الزمنية
/// يحتاج تحديدًا من عقد الـAPI.
LogEventDaySlice? sliceLogEventToDay(LogEvent event, DateTime logDate) {
  final day = logDate.toLocal();
  final midnight = DateTime(day.year, day.month, day.day);
  final start = event.startTime.toLocal();

  final startMinutes = start.difference(midnight).inMinutes;
  final endMinutes = startMinutes + event.duration.inMinutes;

  if (endMinutes <= 0 || startMinutes >= _minutesPerDay) return null;

  final clippedStart = startMinutes.clamp(0, _minutesPerDay);
  final clippedEnd = endMinutes.clamp(0, _minutesPerDay);
  final visibleMinutes = clippedEnd - clippedStart;
  if (visibleMinutes <= 0) return null;

  return LogEventDaySlice(
    startHour: clippedStart / 60.0,
    endHour: clippedEnd / 60.0,
    visibleDuration: Duration(minutes: visibleMinutes),
  );
}

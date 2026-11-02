import 'daily_log.dart';

/// مصدر أحداث السجل المعروضة.
enum LogEventsSource {
  /// استجابة صالحة من الخادم، وتشمل القائمة الفارغة المؤكدة.
  server,

  /// لقطة صالحة محفوظة من استجابة سابقة.
  cache,

  /// أحداث سُجّلت على الجهاز فقط.
  local,
}

/// قائمة أحداث مع مصدرها، حتى تفرّق الواجهة بين نجاح فارغ، وبيانات
/// محفوظة/محلية، وفشل بلا بيانات صالحة.
class LogEventsSnapshot {
  final List<LogEvent> events;
  final LogEventsSource source;

  const LogEventsSnapshot({required this.events, required this.source});

  const LogEventsSnapshot.server(List<LogEvent> events)
    : this(events: events, source: LogEventsSource.server);

  const LogEventsSnapshot.cache(List<LogEvent> events)
    : this(events: events, source: LogEventsSource.cache);

  const LogEventsSnapshot.local(List<LogEvent> events)
    : this(events: events, source: LogEventsSource.local);

  /// ليست استجابة خادم حديثة — تُعرض مع تنبيه للمستخدم.
  bool get isSavedData => source != LogEventsSource.server;
}

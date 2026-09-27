class StorageConstants {
  // SharedPreferences Keys
  static const String serverUrl = 'url';
  static const String deviceId = 'id';
  static const String eventLogs = 'event_logs';

  // Hive Box Names
  static const String eventsBox = 'events_box';
  static const String periodsBox = 'periods_box';
  static const String auditBox = 'audit_box';

  /// SRS 6.8 — last server snapshot of the daily-logs list and each day's
  /// graph-grid events, served read-only while offline.
  static const String dailyLogsCacheBox = 'daily_logs_cache_box';
}

class StorageConstants {
  // SharedPreferences Keys
  static const String serverUrl = 'url';
  static const String deviceId = 'id';
  static const String eventLogs = 'event_logs';

  // Hive Box Names
  static const String eventsBox = 'events_box';
  static const String periodsBox = 'periods_box';

  /// سجل تدقيق السجلات اليومية (LogLocalDataSource).
  /// القيمة فيه **قائمة JSON** لكل يوم، والمفتاح تاريخ `YYYY-MM-DD`.
  static const String auditBox = 'audit_box';

  /// سجل مخالفات HOS (HosAuditRepositoryImpl).
  ///
  /// ⚠️ كان يستخدم [auditBox] نفسه — تصادم مboxes جعل قارئ المخالفات
  /// يفك ترميز قائمة سجلات كأنها كائن مخالفة، فيرمي
  /// `type 'String' is not a subtype of type 'int' of 'index'` ويتعطّل
  /// سجل المخالفات القانوني بالكامل. الصندوق منفصل الآن.
  ///
  /// القيمة فيه **كائن JSON واحد**، والمفتاح `${dateStr}_${violationType}`.
  static const String hosAuditBox = 'hos_audit_box';

  /// SRS 6.8 — last server snapshot of the daily-logs list and each day's
  /// graph-grid events, served read-only while offline.
  static const String dailyLogsCacheBox = 'daily_logs_cache_box';
}

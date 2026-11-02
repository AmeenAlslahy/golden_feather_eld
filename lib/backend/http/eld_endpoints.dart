/// Paths relative to `ApiClient.baseUrl` (the live contract server is `/api`).
///
/// Values match the live OAS 3.0.1 document in `openapi.yaml`
/// (`https://snsoft.cloud/api/eld/openapi.yaml`, fetched 2026-09-23) plus
/// the daily-log API specification (`daily_log_api_specification`, 2026-10)
/// and the HOS Management contract (2026-10):
///   - `GET /eld/daily-logs` (page/size + filters), `GET /eld/daily-logs/summary`
///   - `GET/PUT /eld/daily-logs/{id}/events/{eventId}`, `.../events/options`
///   - `GET /eld/daily-logs/{id}/form/options`, `GET /eld/daily-logs/{id}/certify`
///   - `GET /eld/hos/dashboard`, `GET /eld/hos/recap`
///   - `POST /eld/hos` (AUTO event), `POST /eld/hos/status` (Flutter UI)
/// Do not add a path that is absent from those documents.
library;

class EldEndpoints {
  const EldEndpoints._();

  // ==========================================================================
  // Shared Prefixes
  // ==========================================================================
  static const String _eld = '/eld';

  // ==========================================================================
  // Authentication & Standard Traccar Entities
  // ==========================================================================

  /// جلسة مصادقة Traccar (login)
  static const String authSession = '/session';

  /// طلب إعادة تعيين كلمة المرور
  static const String password = '/password';

  /// قائمة الأجهزة
  static const String devices = '/devices';

  /// المواقع وبيانات التتبع
  static const String positions = '/positions';

  /// أحداث الأجهزة والنظام
  static const String events = '/events';

  /// قائمة السائقين
  static const String drivers = '/drivers';

  /// اتصال مقبس الويب المباشر
  static const String socket = '/socket';

  // ==========================================================================
  // ELD Module APIs (as per openapi.yaml)
  // ==========================================================================

  // 1. Account
  /// الحساب
  static const String account = '$_eld/account';

  /// تفضيلات الحساب
  static const String accountPreferences = '$_eld/account/preferences';

  // 2. HOS — Driver Status Screen (Flutter dashboard)
  //    Reference: HOS Management contract (2026-10)
  /// لوحة الحالة الحية — الساعات الأربع + الحالة النشطة + المركبة
  /// `GET /eld/hos/dashboard`
  static const String statusDashboard = '$_eld/hos/dashboard';

  /// ملخص حالة العمل — 8 أيام + availableTomorrow
  /// `GET /eld/hos/recap`
  static const String statusRecap = '$_eld/hos/recap';

  /// تحديد الحالة من واجهة Flutter — الحمولة: { dutyStatus, notes }
  /// `POST /eld/hos/status`
  static const String updateDutyStatus = '$_eld/hos/status';

  /// تسجيل حدث حالة خدمة كامل (AUTO/MANUAL) — الحمولة: driverId, vehicleId,
  /// status, startTime, ... (§395.26 unidentified driving)
  /// `POST /eld/hos`
  static const String recordDutyStatusEvent = '$_eld/hos';

  // 3. Driver Rules Screen
  static const String rulesScreen = '$_eld/driver-rules';

  // 4. Daily Logs
  /// السجلات اليومية — `GET` list / summary
  static const String dailyLogs = '$_eld/daily-logs';

  /// ملخص السجلات اليومية (إحصاءات مع نفس مرشحات القائمة)
  static const String dailyLogSummary = '$_eld/daily-logs/summary';

  /// تفاصيل سجل يومي محدد
  static String dailyLogDetails(int logId) => '$_eld/daily-logs/$logId';

  /// الرد على تعديلات الناقل
  static String respondCarrierEdit(int logId, String editId) =>
      '$_eld/daily-logs/$logId/carrier-edits/$editId/respond';

  /// المصادقة على السجل
  static String certifyLog(int logId) => '$_eld/daily-logs/$logId/certify';

  /// إعادة تعيين القيادة
  static String reassignDriving(int logId, int statusId) =>
      '$_eld/daily-logs/$logId/events/$statusId/reassign-driving';

  /// نموذج السجل اليومي
  static String dailyLogForm(int logId) => '$_eld/daily-logs/$logId/form';

  /// خيارات النموذج (مركبات مسموحة + سائقون مساعدون — للقوائم المنسدلة)
  static String dailyLogFormOptions(int logId) =>
      '$_eld/daily-logs/$logId/form/options';

  /// أحداث السجل اليومي (GraphGrid + الأحداث القابلة للتعديل)
  static String dailyLogEvents(int logId) => '$_eld/daily-logs/$logId/events';

  /// حدث واحد داخل سجل يومي (تفاصيل/تعديل)
  static String dailyLogEvent(int logId, int eventId) =>
      '$_eld/daily-logs/$logId/events/$eventId';

  /// الخيارات المسموحة لتعديل الأحداث (حالات + تصنيفات خاصة)
  static String dailyLogEventsOptions(int logId) =>
      '$_eld/daily-logs/$logId/events/options';

  /// قفل السجل اليومي
  static String lockLog(int logId) => '$_eld/daily-logs/$logId/lock';

  /// التحقق من جاهزية السجل اليومي
  static String checkReadiness(int logId) =>
      '$_eld/daily-logs/$logId/readiness';

  /// حالة الفريق
  static String teamStatus(int logId) => '$_eld/daily-logs/$logId/team';

  /// مسار قديم (غير موجود في المواصفة الجديدة) — احتياط فقط عندما يعيد
  /// `GET /events` خطأ 404 لأن الخادم لم يُحدَّث بعد. نفس الحمولة: `data.events`.
  @Deprecated('Use dailyLogEvents(logId); legacy fallback only for 404')
  static String dailyLogGraphGrid(int logId) =>
      '$_eld/daily-logs/$logId/graph-grid';

  // 5. Sessions & Connections
  /// جلسة ELD للسائق
  static String eldSession(int driverId) => '$_eld/sessions/$driverId';

  /// أعضاء الجلسة
  static String sessionMembers(int sessionId) =>
      '$_eld/sessions/$sessionId/members';

  /// ربط الجهاز بالجلسة (Live contract: `POST /eld/sessions/connect`)
  static const String connectSession = '$_eld/sessions/connect';

  /// إنهاء الجلسة وفك الارتباط (Live contract: `POST /eld/sessions/disconnect`)
  static const String disconnectSession = '$_eld/sessions/disconnect';

  /// إدارة السائق المساعد
  static const String manageCoDriver = '$_eld/sessions/co-driver';

  /// تبديل السائق الأساسي
  static const String switchPrimaryDriver =
      '$_eld/sessions/primary-driver/switch';

  // 6. Duty Status Events (legacy duty-status controller — prefer HOS above)
  /// ⚠️ Legacy — يُستبدل بـ `recordDutyStatusEvent` عند تحديث الخادم.
  /// التوجيه الكنسي الجديد: `POST /eld/hos`
  @Deprecated('Use recordDutyStatusEvent (/eld/hos) instead')
  static const String legacyRecordDutyStatus = '$_eld/duty-status';

  /// تحديث حالة عمل (legacy)
  @Deprecated('Use updateDutyStatus (/eld/hos/status) instead')
  static String legacyEditDutyStatus(int statusId) =>
      '$_eld/duty-status/$statusId';

  /// نموذج تعديل حالة العمل (legacy)
  @Deprecated('Superseded by dailyLogEventsOptions / HOS contract')
  static String legacyEditDutyStatusForm(int statusId) =>
      '$_eld/duty-status/$statusId/edit-form';

  /// مخطط زمني لحالات العمل (legacy)
  @Deprecated('Use dailyLogEvents or statusDashboard')
  static const String legacyGraphGridTimeline = '$_eld/duty-status/graph-grid';

  // 7. DVIR Management
  /// إدارة فحص المركبات — GET (list) / POST (create)
  static const String dvir = '$_eld/dvir';

  /// تفاصيل فحص المركبات
  static String dvirDetails(int id) => '$_eld/dvir/$id';

  /// مراجعة وتوقيع تقرير الفحص السابق (§396.13)
  static const String dvirPreviousReview = '$_eld/dvir/previous/review';

  /// مراجعة فحص المركبات حسب المعرف (Legacy / Specific)
  @Deprecated('Use dvirPreviousReview for §396.13 flow')
  static String dvirNextDriverReview(int id) => '$_eld/dvir/$id/review';

  /// دليل بنود الفحص الإلزامية الـ 11 (§396.11)
  static const String dvirCatalog = '$_eld/dvir/catalog';

  /// استرجاع تقرير الفحص السابق للمركبة (§396.13)
  static const String dvirPreviousReport = '$_eld/dvir/previous';

  /// فحص المركبات السابق حسب المعرف الفرعي (Legacy route)
  @Deprecated('Use dvirPreviousReport for §396.13')
  static String dvirPrevious(String uniqueId) =>
      '$_eld/dvir/pre-trip/$uniqueId';

  /// مزامنة فحوصات وضع عدم الاتصال
  static const String dvirSync = '$_eld/dvir/sync';

  /// تفاصيل عيب DVIR (سجل الإصلاحات والاعتمادات)
  static String dvirDefectDetails(int id) => '$_eld/dvir/defects/$id';

  /// العيوب النشطة لمركبة محددة
  static String dvirVehicleDefects(String uniqueId) =>
      '$_eld/dvir/defects/device/$uniqueId';

  // 14. Roadside Inspection
  //     Live contract screen is `GET /eld/dot-inspection`.
  /// تفتيش الطرق
  static const String inspections = '$_eld/inspections';

  /// سجلات الدورة (8 أيام أو نطاق التدقيق)
  static const String dotInspectionCycle = '$inspections/cycle';

  /// عرض سجل التفتيش ليوم محدد
  static const String dotInspectionLogs = '$inspections/logs';

  /// بدء تفتيش الطرق
  static const String dotInspectionStart = '$inspections/start';

  /// حزمة المعلومات لتفتيش الطرق
  static const String dotInspectionPacket = '$inspections/information-packet';

  /// تحويلات تفتيش الطرق
  static const String dotInspectionTransfers = '$inspections/transfers';

  /// إرسال السجلات عبر بريد التفتيش
  static const String dotInspectionSendLogs = '$inspections/send-logs';

  /// البريد الإلكتروني لتفتيش الطرق — `POST /eld/transfer/email-logs`
  static const String dotInspectionEmailLogs = '$_eld/transfer/email-logs';

  // 17. Hardware
  /// تنبيهات الجهاز
  static const String hardwareAlerts = '$_eld/hardware/alerts';

  /// الوضع اليدوي
  static const String hardwareManualMode = '$_eld/hardware/manual-mode';

  /// جاهزية الجهاز
  static const String hardwareReadiness = '$_eld/hardware/readiness';

  /// حالة الجهاز
  static const String hardwareStatus = '$_eld/hardware/status';

  /// بث قراءات المحرك اللحظية
  static const String hardwareTelemetry = '$_eld/hardware/telemetry';

  // ==========================================================================
  // Driver-scope contract paths (SRS §7.13, §7.15, §9.1, §11)
  // ==========================================================================

  /// قائمة الأحداث غير المحددة
  static const String unidentifiedEvents = '$_eld/unidentified';

  /// تفاصيل حدث غير محدد
  static String unidentifiedEvent(int id) => '$_eld/unidentified/$id';

  /// ملخص الأحداث غير المحددة وتنبيه الـ 8 أيام
  static const String unidentifiedSummary = '$_eld/unidentified/summary';

  /// المطالبة بالأحداث غير المعرفة
  static String claimUnidentified(int id) => '$_eld/unidentified/$id/claim';

  /// رفض الأحداث غير المعرفة
  static String rejectUnidentified(int id) => '$_eld/unidentified/$id/reject';

  /// مركبات الشركة
  static const String companyVehicles = '$_eld/vehicles';

  /// مركباتي
  static const String myVehicles = '$_eld/vehicles/my-vehicles';

  // ==========================================================================
  // Deprecated Aliases (for backward compatibility)
  // ==========================================================================

  @Deprecated('Use authSession instead')
  static const String session = authSession;

  @Deprecated('Use statusDashboard instead')
  static const String status = statusDashboard;

  @Deprecated('Use recordDutyStatusEvent instead')
  static const String recordDutyStatus = recordDutyStatusEvent;

  @Deprecated('Use legacyGraphGridTimeline instead')
  static const String graphGridTimeline = legacyGraphGridTimeline;

  @Deprecated('Use eldSession instead')
  static String getSession(int driverId) => eldSession(driverId);

  @Deprecated('Use legacyEditDutyStatus instead')
  static String editDutyStatus(int statusId) => legacyEditDutyStatus(statusId);

  @Deprecated('Use legacyEditDutyStatusForm instead')
  static String editDutyStatusForm(int statusId) =>
      legacyEditDutyStatusForm(statusId);
}
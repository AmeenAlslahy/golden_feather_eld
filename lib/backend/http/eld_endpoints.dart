library;

/// Paths relative to `ApiClient.baseUrl` (the live contract server is `/api`).
///
/// Values match the live OAS 3.0.1 document in `openapi.yaml`
/// (`https://snsoft.cloud/api/eld/openapi.yaml`, fetched 2026-09-23).
/// Do not add a path that is absent from that file.
class EldEndpoints {
  const EldEndpoints._();

  // ==========================================================================
  // Authentication & Standard Traccar Entities
  // ==========================================================================
  /// جلسة
  static const String session = '/session';
  /// أجهزة
  static const String devices = '/devices';

  // ==========================================================================
  // ELD Module APIs (as per openapi.yaml)
  // ==========================================================================

  // 1. Account & Profile
  /// ملف السائق 
  static String profile(int driverId) => '/eld/profile/$driverId';
  /// الحساب
  static const String account = '/eld/account';
  /// تفضيلات الحساب
  static const String accountPreferences = '/eld/account/preferences';

  // 2. Status Dashboard
  /// لوحة التحكم 
  static const String status = '/eld/status';
  /// تحديث حالة العمل
  static const String updateDutyStatus = '/eld/status/duty-status'; // (POST) Update duty status
  /// ملخص حالة العمل
  static const String statusRecap = '/eld/status/recap';

  // 3. Driver Rules Screen
  static const String rulesScreen = '/eld/rules-screen';

  // 4. Daily Logs
  /// السجلات اليومية
  static const String dailyLogs = '/eld/daily-logs';
  /// تفاصيل السجلات اليومية
  static String dailyLogDetails(int logId) => '/eld/daily-logs/$logId';
  /// تعديلات الناقل
  static String proposeCarrierEdit(int logId) => '/eld/daily-logs/$logId/carrier-edits';
  /// الرد على تعديلات الناقل
  static String respondCarrierEdit(int logId, String editId) => '/eld/daily-logs/$logId/carrier-edits/$editId/respond';
  /// المصادقة على السجل
  static String certifyLog(int logId) => '/eld/daily-logs/$logId/certify';
  /// إعادة تعيين القيادة
  static String reassignDriving(int logId, int statusId) => '/eld/daily-logs/$logId/events/$statusId/reassign-driving';
  /// نموذج السجلات اليومية
  static String dailyLogForm(int logId) => '/eld/daily-logs/$logId/form';
  /// مخطط زمني للسجلات اليومية
  static String dailyLogGraphGrid(int logId) => '/eld/daily-logs/$logId/graph-grid';
  /// قفل السجلات اليومية
  static String lockLog(int logId) => '/eld/daily-logs/$logId/lock';
  /// التحقق من جاهزية السجلات اليومية
  static String checkReadiness(int logId) => '/eld/daily-logs/$logId/readiness';
  /// حالة الفريق
  static String teamStatus(int logId) => '/eld/daily-logs/$logId/team';

  // 5. Sessions & Connections
  /// الحصول على الجلسة
  static String getSession(int driverId) => '/eld/sessions/$driverId';
  /// أعضاء الجلسة
  static String sessionMembers(int sessionId) => '/eld/sessions/$sessionId/members';
  /// Live contract: `POST /eld/hardware/connect`. `/eld/sessions/connect` does not exist.
  /// ربط الجهاز بالجلسة
  static const String connectSession = '/eld/hardware/connect';
  /// إدارة السائق المساعد
  static const String manageCoDriver = '/eld/sessions/co-driver';
  /// تبديل السائق الأساسي
  static const String switchPrimaryDriver = '/eld/sessions/primary-driver/switch';

  // 6. Duty Status Events
  /// حالات العمل
  static const String recordDutyStatus = '/eld/duty-status';
  /// تحديث حالة العمل
  static String editDutyStatus(int statusId) => '/eld/duty-status/$statusId';
  /// نموذج تعديل حالة العمل
  static String editDutyStatusForm(int statusId) => '/eld/duty-status/$statusId/edit-form';
  /// مخطط زمني لحالات العمل
  static const String graphGridTimeline = '/eld/duty-status/graph-grid';

  // 7. DVIR Management
  /// إدارة فحص المركبات 
  static const String dvir = '/eld/dvir';
  /// تفاصيل فحص المركبات 
  static String dvirDetails(int id) => '/eld/dvir/$id';
  /// شهادة إصلاح المركبات 
  static String certifyDvirRepair(int id) => '/eld/dvir/$id/certify-repair';
  /// مراجعة فحص المركبات 
  static String dvirNextDriverReview(int id) => '/eld/dvir/$id/review';
  /// كتالوج فحص المركبات 
  static const String dvirCatalog = '/eld/dvir/catalog';
  /// فحص المركبات السابق 
  static String dvirPrevious(String uniqueId) => '/eld/dvir/pre-trip/$uniqueId';

  // 9. System Configuration
  /// إعدادات النظام 
  static const String config = '/eld/config';
  /// Live contract: `GET /eld/config/settings`.
  /// إعدادات قاعدة البيانات
  static const String configDbSettings = '/eld/config/settings';
  /// Live contract: `GET /eld/config/rules`.
  /// قواعد العمل
  static const String configRegulations = '/eld/config/rules';

  // 14. Roadside Inspection
  /// Live contract screen is `GET /eld/dot-inspection`, not `/eld/inspections`.
  /// تفتيش الطرق
  static const String inspections = '/eld/dot-inspection';

  // 17. Hardware
  /// تنبيةات الجهاز
  static const String hardwareAlerts = '/eld/hardware/alerts';
  /// الوضع اليدوي
  static const String hardwareManualMode = '/eld/hardware/manual-mode';
  /// جاهزية الجهاز 
  static const String hardwareReadiness = '/eld/hardware/readiness';
  /// حالة الجهاز
  static const String hardwareStatus = '/eld/hardware/status';
  /// قياسات الجهاز
  static const String hardwareTelemetry = '/eld/hardware/telemetry';

  // Driver-scope contract paths (SRS §7.13, §7.15, §9.1, §11).
  /// الاحداث الغير معرفة 
  static const String unidentifiedEvents = '/eld/unidentified-events';
  /// المطالبة بالاحداث الغير معرفة 
  static String claimUnidentified(int id) => '/eld/unidentified-events/$id/claim';
  /// رفض الاحداث الغير معرفة 
  static String rejectUnidentified(int id) => '/eld/unidentified-events/$id/reject';
  /// مركبات الشركة 
  static const String companyVehicles = '/eld/company-vehicles';
  /// مركباتي 
  static const String myVehicles = '/eld/company-vehicles/my-vehicles';
  /// البريد الإلكتروني لتفتيش الطرق 
  static const String dotInspectionEmailLogs = '/eld/dot-inspection/email-logs';
  /// ارسال السجلات عبر البريد الإلكتروني
  static const String dotInspectionSendLogs = '/eld/dot-inspection/send-logs';
  /// بدء تفتيش الطرق 
  static const String dotInspectionStart = '/eld/dot-inspection/start';
  /// حزمة المعلومات لتفتيش الطرق 
  static const String dotInspectionPacket = '/eld/dot-inspection/information-packet';
  /// تحويلات تفتيش الطرق 
  static const String dotInspectionTransfers = '/eld/dot-inspection/transfers';
}

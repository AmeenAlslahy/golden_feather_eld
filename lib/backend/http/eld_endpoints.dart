library;

/// Centralized API endpoints based on openapi.yaml specifications.
///
/// **IMPORTANT**: All paths here are relative to the `ApiClient`'s `baseUrl`
/// (which usually ends with `/api`).
/// DO NOT include the base URL or `/api` prefix in these strings unless strictly
/// necessary (e.g., if a specific endpoint bypasses the `/api` prefix).
class EldEndpoints {
  const EldEndpoints._();

  // ==========================================================================
  // Authentication & Standard Traccar Entities
  // ==========================================================================
  
  static const String session = '/session';
  static const String users = '/users';
  static const String devices = '/devices';

  // ==========================================================================
  // ELD Module APIs (as per openapi.yaml)
  // ==========================================================================

  // 1. Account & Profile
  static String profile(int driverId) => '/eld/profile/$driverId';
  static const String account = '/eld/account';
  static const String accountPreferences = '/eld/account/preferences';

  // 2. Status Dashboard
  static const String status = '/eld/status';
  static const String dutyStatusPost = '/eld/status/duty-status'; // (POST) Update duty status
  static const String statusRecap = '/eld/status/recap';

  // 3. Driver Rules Screen
  static const String rulesScreen = '/eld/rules-screen';

  // 4. Daily Logs
  static const String dailyLogs = '/eld/daily-logs';
  static String dailyLogDetails(int logId) => '/eld/daily-logs/$logId';
  static String proposeCarrierEdit(int logId) => '/eld/daily-logs/$logId/carrier-edits';
  static String respondCarrierEdit(int logId, String editId) => '/eld/daily-logs/$logId/carrier-edits/$editId/respond';
  static String certifyLog(int logId) => '/eld/daily-logs/$logId/certify';
  static String reassignDriving(int logId, int statusId) => '/eld/daily-logs/$logId/events/$statusId/reassign-driving';
  static String dailyLogForm(int logId) => '/eld/daily-logs/$logId/form';
  static String dailyLogGraphGrid(int logId) => '/eld/daily-logs/$logId/graph-grid';
  static String lockLog(int logId) => '/eld/daily-logs/$logId/lock';
  static String checkReadiness(int logId) => '/eld/daily-logs/$logId/readiness';
  static String teamStatus(int logId) => '/eld/daily-logs/$logId/team';

  // 5. Sessions & Connections
  static String getSession(int driverId) => '/eld/sessions/$driverId';
  static String sessionMembers(int sessionId) => '/eld/sessions/$sessionId/members';
  static const String connectSession = '/eld/sessions/connect';
  static const String manageCoDriver = '/eld/sessions/co-driver';
  static const String switchPrimaryDriver = '/eld/sessions/primary-driver/switch';

  // 6. Duty Status Events
  static const String dutyStatus = '/eld/duty-status';
  static String updateDutyStatus(int statusId) => '/eld/duty-status/$statusId';
  static String editDutyStatusForm(int statusId) => '/eld/duty-status/$statusId/edit-form';
  static const String graphGridTimeline = '/eld/duty-status/graph-grid';

  // 7. DVIR Management
  static const String dvir = '/eld/dvir';
  static String dvirDetails(int id) => '/eld/dvir/$id';
  static String certifyDvirRepair(int id) => '/eld/dvir/$id/certify-repair';
  static String dvirNextDriverReview(int id) => '/eld/dvir/$id/review';

  // 8. Compliance Engine
  static String evaluateCompliance(int driverId) => '/eld/compliance/$driverId/evaluate';
  static String complianceRemaining(int driverId) => '/eld/compliance/$driverId/remaining';

  // 9. System Configuration
  static const String config = '/eld/config';
  static const String configDbSettings = '/eld/config/db-settings';
  static const String configRegulations = '/eld/config/regulations';
  static const String activeRegulation = '/eld/config/regulations/active';

  // 10. Dashboard
  static const String dashboardSummary = '/eld/dashboard/summary';
  static const String dashboardStream = '/eld/dashboard/stream';

  // 11. Diagnostics & Malfunctions
  static String clearDiagnostic(int id) => '/eld/diagnostics/$id/clear';
  static String driverDiagnostics(int driverId) => '/eld/diagnostics/$driverId';
  static const String fleetDiagnostics = '/eld/diagnostics/fleet';

  // 12. Documents
  static String document(int id) => '/eld/documents/$id';
  static String downloadDocument(int docId) => '/eld/documents/download/$docId';
  static String driverDocuments(int driverId) => '/eld/documents/$driverId';
  static String uploadDocumentFile(int driverId) => '/eld/documents/$driverId/upload-file';
  static String verifyDocument(int id) => '/eld/documents/$id/verify';

  // 13. System Health
  static const String healthDetailed = '/eld/health/detailed';
  static const String health = '/eld/health';

  // 14. Roadside Inspection
  static String completeInspection(int id) => '/eld/inspections/$id/complete';
  static String inspectionBlePackets(int id) => '/eld/inspections/$id/transfer/ble-packets';
  static String inspectionReport(int id) => '/eld/inspections/$id/report';
  static String inspectionHtmlReport(int id) => '/eld/inspections/$id/report/html';
  static String driverInspections(int driverId) => '/eld/inspections/driver/$driverId';
  static String inspectionDataFile(int id) => '/eld/inspections/$id/data-file';
  static String inspectionDetails(int id) => '/eld/inspections/$id';
  static String inspectionQrCode(int id) => '/eld/inspections/$id/qr';
  static String inspectionUsbTransfer(int id) => '/eld/inspections/$id/transfer/usb';
  static String inspectionInitiateTransfer(int id) => '/eld/inspections/$id/transfer';
  static const String inspections = '/eld/inspections';

  // 15. ELD Reports
  static const String generateReport = '/eld/reports/generate';
  static String csvReport(int driverId) => '/eld/reports/$driverId/csv';
  static String dailyReport(int driverId) => '/eld/reports/$driverId/daily';

  // 16. Signatures
  static String signatures(int driverId) => '/eld/signatures/$driverId';

  // 17. Hardware
  static const String hardwareTelemetry = '/eld/hardware/telemetry';
}

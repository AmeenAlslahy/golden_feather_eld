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
  
  static const String session = '/session';
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
  /// Live contract: `POST /eld/hardware/connect`. `/eld/sessions/connect` does not exist.
  static const String connectSession = '/eld/hardware/connect';
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
  static const String dvirCatalog = '/eld/dvir/catalog';
  static String dvirPrevious(String uniqueId) => '/eld/dvir/pre-trip/$uniqueId';

  // 9. System Configuration
  static const String config = '/eld/config';
  /// Live contract: `GET /eld/config/settings`.
  static const String configDbSettings = '/eld/config/settings';
  /// Live contract: `GET /eld/config/rules`.
  static const String configRegulations = '/eld/config/rules';

  // 14. Roadside Inspection
  /// Live contract screen is `GET /eld/dot-inspection`, not `/eld/inspections`.
  static const String inspections = '/eld/dot-inspection';

  // 17. Hardware
  static const String hardwareAlerts = '/eld/hardware/alerts';
  static const String hardwareManualMode = '/eld/hardware/manual-mode';
  static const String hardwareReadiness = '/eld/hardware/readiness';
  static const String hardwareStatus = '/eld/hardware/status';
  static const String hardwareTelemetry = '/eld/hardware/telemetry';

  // Driver-scope contract paths (SRS §7.13, §7.15, §9.1, §11).
  static const String unidentifiedEvents = '/eld/unidentified-events';
  static String claimUnidentified(int id) => '/eld/unidentified-events/$id/claim';
  static String rejectUnidentified(int id) => '/eld/unidentified-events/$id/reject';
  static const String companyVehicles = '/eld/company-vehicles';
  static const String myVehicles = '/eld/company-vehicles/my-vehicles';
  static const String dotInspectionEmailLogs = '/eld/dot-inspection/email-logs';
  static const String dotInspectionSendLogs = '/eld/dot-inspection/send-logs';
  static const String dotInspectionStart = '/eld/dot-inspection/start';
  static const String dotInspectionPacket = '/eld/dot-inspection/information-packet';
  static const String dotInspectionTransfers = '/eld/dot-inspection/transfers';
}

import '../contracts/account_backend.dart';
import '../contracts/daily_logs_backend.dart';
import '../contracts/driver_session_backend.dart';
import '../contracts/duty_status_backend.dart';
import '../contracts/dvir_backend.dart';
import '../contracts/hardware_backend.dart';
import '../contracts/inspection_backend.dart';
import '../contracts/rules_screen_backend.dart';
import '../contracts/signature_backend.dart';
import '../contracts/status_dashboard_backend.dart';
import '../contracts/unidentified_events_backend.dart';
import '../contracts/vehicle_backend.dart';
import '../contracts/auth_backend.dart';
import 'backend_identity.dart';

/// Aggregator for all backend contracts.
///
/// Each getter returns the corresponding contract implementation,
/// or `null` if the backend does not support it.
///
/// **Rule:** Adapters must be pure aggregators. No business logic.
abstract class BackendAdapter {
  BackendIdentity get identity;

  bool get isMock => identity.isMock;

  // ==========================================================================
  // Contracts — all nullable (a backend may not support all features)
  // ==========================================================================

  AuthBackend? get auth;

  AccountBackend? get account;

  StatusDashboardBackend? get statusDashboard;

  RulesScreenBackend? get rulesScreen;

  DailyLogsBackend? get dailyLogs;

  DutyStatusBackend? get dutyStatus;

  DriverSessionBackend? get driverSession;

  DvirBackend? get dvir;

  InspectionBackend? get inspection;

  UnidentifiedEventsBackend? get unidentifiedEvents;

  VehicleBackend? get vehicle;

  HardwareBackend? get hardware;


  SignatureBackend? get signature;

  // ==========================================================================

  Future<void> dispose();
}

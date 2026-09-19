import '../../contracts/account_backend.dart';
import '../../contracts/auth_backend.dart';
import '../../contracts/compliance_backend.dart';
import '../../contracts/config_backend.dart';
import '../../contracts/daily_logs_backend.dart';
import '../../contracts/driver_rules_backend.dart';
import '../../contracts/driver_session_backend.dart';
import '../../contracts/duty_status_backend.dart';
import '../../contracts/dvir_backend.dart';
import '../../contracts/fleet_dashboard_backend.dart';
import '../../contracts/hardware_backend.dart';
import '../../contracts/health_backend.dart';
import '../../contracts/inspection_backend.dart';
import '../../contracts/log_transfer_backend.dart';
import '../../contracts/reports_backend.dart';
import '../../contracts/rules_engine_backend.dart';
import '../../contracts/rules_screen_backend.dart';
import '../../contracts/signature_backend.dart';
import '../../contracts/stats_backend.dart';
import '../../contracts/status_dashboard_backend.dart';
import '../../contracts/unidentified_events_backend.dart';
import '../../contracts/vehicle_backend.dart';
import '../../core/backend_adapter.dart';
import '../../core/backend_identity.dart';
import 'sub/mock_account_backend.dart';
import 'sub/mock_auth_backend.dart';
import 'sub/mock_compliance_backend.dart';
import 'sub/mock_config_backend.dart';
import 'sub/mock_daily_logs_backend.dart';
import 'sub/mock_driver_rules_backend.dart';
import 'sub/mock_driver_session_backend.dart';
import 'sub/mock_duty_status_backend.dart';
import 'sub/mock_dvir_backend.dart';
import 'sub/mock_fleet_dashboard_backend.dart';
import 'sub/mock_hardware_backend.dart';
import 'sub/mock_health_backend.dart';
import 'sub/mock_inspection_backend.dart';
import 'sub/mock_log_transfer_backend.dart';
import 'sub/mock_reports_backend.dart';
import 'sub/mock_rules_engine_backend.dart';
import 'sub/mock_rules_screen_backend.dart';
import 'sub/mock_signature_backend.dart';
import 'sub/mock_stats_backend.dart';
import 'sub/mock_status_dashboard_backend.dart';
import 'sub/mock_unidentified_events_backend.dart';
import 'sub/mock_vehicle_backend.dart';

/// In-memory backend for development, demos, and tests.
///
/// **Status in T1.8:**
/// - 3 contracts are fully mocked (health, account, statusDashboard).
/// - 17 contracts throw [UnimplementedError] (filled in Phase 2).
///
/// **Rule:** No network access. No timers. No platform channels.
class MockAdapter implements BackendAdapter {
  @override
  final BackendIdentity identity;

  @override
  bool get isMock => identity.isMock;


  MockAdapter._({required this.identity});

  /// Creates a mock adapter with a fixed identity.
  factory MockAdapter() {
    return MockAdapter._(identity: BackendIdentity.mock());
  }

  // ==========================================================================
  // Fully-mocked contracts (T1.8)
  // ==========================================================================

  @override
  late final AuthBackend auth = const MockAuthBackend();

  @override
  late final HealthBackend health = const MockHealthBackend();

  @override
  late final AccountBackend account = MockAccountBackend();

  @override
  late final SignatureBackend signature = MockSignatureBackend();

  @override
  late final StatusDashboardBackend statusDashboard =
      MockStatusDashboardBackend();

  // ==========================================================================
  // Skeleton contracts (Phase 2)
  // ==========================================================================

  @override
  late final RulesScreenBackend rulesScreen = const MockRulesScreenBackend();

  @override
  late final DailyLogsBackend dailyLogs = const MockDailyLogsBackend();

  @override
  late final DutyStatusBackend dutyStatus = const MockDutyStatusBackend();

  @override
  late final DriverSessionBackend driverSession =
      const MockDriverSessionBackend();

  @override
  late final DvirBackend dvir = const MockDvirBackend();

  @override
  late final InspectionBackend inspection = MockInspectionBackend();

  @override
  late final UnidentifiedEventsBackend unidentifiedEvents =
      const MockUnidentifiedEventsBackend();

  @override
  late final VehicleBackend vehicle = const MockVehicleBackend();

  @override
  late final HardwareBackend hardware = MockHardwareBackend();

  @override
  late final RulesEngineBackend rulesEngine = const MockRulesEngineBackend();

  @override
  late final DriverRulesBackend driverRules = const MockDriverRulesBackend();

  @override
  late final LogTransferBackend logTransfer = const MockLogTransferBackend();

  @override
  late final ReportsBackend reports = const MockReportsBackend();

  @override
  late final StatsBackend stats = const MockStatsBackend();

  @override
  late final ComplianceBackend compliance = const MockComplianceBackend();

  @override
  late final ConfigBackend config = const MockConfigBackend();

  @override
  late final FleetDashboardBackend fleetDashboard =
      const MockFleetDashboardBackend();

  // ==========================================================================

  @override
  Future<void> dispose() async {
    // Mocks hold only in-memory state; nothing to release.
  }
}

import '../../contracts/account_backend.dart';
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
import '../../contracts/stats_backend.dart';
import '../../contracts/status_dashboard_backend.dart';
import '../../contracts/unidentified_events_backend.dart';
import '../../contracts/vehicle_backend.dart';
import '../../core/backend_adapter.dart';
import '../../core/backend_identity.dart';
import '../../http/api_client.dart';
import 'sub/eld_account_backend.dart';
import 'sub/eld_compliance_backend.dart';
import 'sub/eld_config_backend.dart';
import 'sub/eld_daily_logs_backend.dart';
import 'sub/eld_driver_rules_backend.dart';
import 'sub/eld_driver_session_backend.dart';
import 'sub/eld_duty_status_backend.dart';
import 'sub/eld_dvir_backend.dart';
import 'sub/eld_fleet_dashboard_backend.dart';
import 'sub/eld_hardware_backend.dart';
import 'sub/eld_health_backend.dart';
import 'sub/eld_inspection_backend.dart';
import 'sub/eld_log_transfer_backend.dart';
import 'sub/eld_reports_backend.dart';
import 'sub/eld_rules_engine_backend.dart';
import 'sub/eld_rules_screen_backend.dart';
import 'sub/eld_stats_backend.dart';
import 'sub/eld_status_dashboard_backend.dart';
import 'sub/eld_unidentified_events_backend.dart';
import 'sub/eld_vehicle_backend.dart';

/// Aggregator for all ELD Engine contracts.
///
/// Constructed once by the composition root. Sub-adapters are lazily
/// instantiated on first access — since they are stateless, this is
/// cheap.
///
/// **Rule:** No business logic here. Only aggregation.
class EldEngineAdapter implements BackendAdapter {
  @override
  final BackendIdentity identity;

  @override
  bool get isMock => identity.isMock;

  final ApiClient _apiClient;

  // ==========================================================================
  // Contracts — lazily initialized, stateless
  // ==========================================================================

  @override
  late final AccountBackend account = EldAccountBackend(_apiClient);

  @override
  late final StatusDashboardBackend statusDashboard =
      EldStatusDashboardBackend(_apiClient);

  @override
  late final RulesScreenBackend rulesScreen =
      EldRulesScreenBackend(_apiClient);

  @override
  late final DailyLogsBackend dailyLogs = EldDailyLogsBackend(_apiClient);

  @override
  late final DutyStatusBackend dutyStatus = EldDutyStatusBackend(_apiClient);

  @override
  late final DriverSessionBackend driverSession =
      EldDriverSessionBackend(_apiClient);

  @override
  late final DvirBackend dvir = EldDvirBackend(_apiClient);

  @override
  late final InspectionBackend inspection =
      EldInspectionBackend(_apiClient);

  @override
  late final UnidentifiedEventsBackend unidentifiedEvents =
      EldUnidentifiedEventsBackend(_apiClient);

  @override
  late final VehicleBackend vehicle = EldVehicleBackend(_apiClient);

  @override
  late final HardwareBackend hardware = EldHardwareBackend(_apiClient);

  @override
  late final RulesEngineBackend rulesEngine =
      EldRulesEngineBackend(_apiClient);

  @override
  late final DriverRulesBackend driverRules =
      EldDriverRulesBackend(_apiClient);

  @override
  late final LogTransferBackend logTransfer =
      EldLogTransferBackend(_apiClient);

  @override
  late final HealthBackend health = EldHealthBackend(_apiClient);

  @override
  late final ReportsBackend reports = EldReportsBackend(_apiClient);

  @override
  late final StatsBackend stats = EldStatsBackend(_apiClient);

  @override
  late final ComplianceBackend compliance =
      EldComplianceBackend(_apiClient);

  @override
  late final ConfigBackend config = EldConfigBackend(_apiClient);

  @override
  late final FleetDashboardBackend fleetDashboard =
      EldFleetDashboardBackend(_apiClient);

  // ==========================================================================

  EldEngineAdapter._({
    required this.identity,
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Creates an ELD Engine adapter.
  factory EldEngineAdapter.create({
    required String baseUrl,
    required ApiClient apiClient,
  }) {
    return EldEngineAdapter._(
      identity: BackendIdentity.eldEngine(baseUrl: baseUrl),
      apiClient: apiClient,
    );
  }

  @override
  Future<void> dispose() async {
    // Sub-adapters are stateless (they only hold ApiClient reference).
    // No resources to release.
  }
}

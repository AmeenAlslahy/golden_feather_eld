import '../../contracts/account_backend.dart';
import '../../contracts/auth_backend.dart';
import '../../contracts/daily_logs_backend.dart';
import '../../contracts/driver_session_backend.dart';
import '../../contracts/duty_status_backend.dart';
import '../../contracts/dvir_backend.dart';
import '../../contracts/hardware_backend.dart';
import '../../contracts/inspection_backend.dart';
import '../../contracts/rules_screen_backend.dart';
import '../../contracts/signature_backend.dart';
import '../../contracts/status_dashboard_backend.dart';
import '../../contracts/unidentified_events_backend.dart';
import '../../contracts/vehicle_backend.dart';
import '../../core/backend_adapter.dart';
import '../../core/backend_identity.dart';
import '../../http/api_client.dart';
import 'sub/eld_account_backend.dart';
import 'sub/eld_auth_backend.dart';
import 'sub/eld_daily_logs_backend.dart';
import 'sub/eld_driver_session_backend.dart';
import 'sub/eld_duty_status_backend.dart';
import 'sub/eld_dvir_backend.dart';
import 'sub/eld_hardware_backend.dart';
import 'sub/eld_inspection_backend.dart';
import 'sub/eld_rules_screen_backend.dart';
import 'sub/eld_signature_backend.dart';
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
  late final AuthBackend auth = EldAuthBackend(_apiClient);

  @override
  late final AccountBackend account = EldAccountBackend(_apiClient);

  @override
  late final SignatureBackend signature = EldSignatureBackend(_apiClient);

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

import '../../../../core/result/result.dart';
import '../../../contracts/fleet_dashboard_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [FleetDashboardBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockFleetDashboardBackend implements FleetDashboardBackend {
  const MockFleetDashboardBackend();

  @override
  Future<Result<RawJson>> getSummary({int? groupId}) =>
      throw UnimplementedError(
        'MockFleetDashboardBackend.getSummary — Phase 2',
      );

  @override
  Stream<RawJson> streamEvents() =>
      throw UnimplementedError(
        'MockFleetDashboardBackend.streamEvents — Phase 4',
      );
}

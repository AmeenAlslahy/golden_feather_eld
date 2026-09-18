// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../contracts/fleet_dashboard_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [FleetDashboardBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldFleetDashboardBackend implements FleetDashboardBackend {
  final ApiClient _apiClient;

  const EldFleetDashboardBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getSummary({int? groupId}) =>
      throw UnimplementedError('EldFleetDashboardBackend.getSummary — Phase 2');

  @override
  Stream<RawJson> streamEvents() =>
      throw UnimplementedError('EldFleetDashboardBackend.streamEvents — Phase 4');
}

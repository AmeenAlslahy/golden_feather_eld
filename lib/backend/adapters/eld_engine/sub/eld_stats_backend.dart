// ignore_for_file: unused_field, unused_import

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/stats_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [StatsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldStatsBackend implements StatsBackend {
  final ApiClient _apiClient;

  const EldStatsBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getFleetStats() =>
      throw UnimplementedError('EldStatsBackend.getFleetStats — Phase 2');

  @override
  Future<Result<RawJson>> getDriverComplianceScore(DriverId driverId) =>
      throw UnimplementedError('EldStatsBackend.getDriverComplianceScore — Phase 2');
}

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/stats_backend.dart';

/// In-memory mock for [StatsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockStatsBackend implements StatsBackend {
  const MockStatsBackend();

  @override
  Future<Result<RawJson>> getFleetStats() =>
      throw UnimplementedError('MockStatsBackend.getFleetStats — Phase 2');

  @override
  Future<Result<RawJson>> getDriverComplianceScore(DriverId driverId) =>
      throw UnimplementedError(
        'MockStatsBackend.getDriverComplianceScore — Phase 2',
      );
}

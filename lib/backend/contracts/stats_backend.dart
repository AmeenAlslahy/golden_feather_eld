import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class StatsBackend {
  /// GET /eld/stats
  Future<Result<RawJson>> getFleetStats();

  /// GET /eld/stats/driver/{driverId}
  Future<Result<RawJson>> getDriverComplianceScore(DriverId driverId);
}

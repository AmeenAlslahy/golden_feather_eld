import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class ComplianceBackend {
  /// GET /eld/compliance/evaluate/{driverId}
  Future<Result<RawJson>> evaluate(DriverId driverId);

  /// GET /eld/compliance/remaining/{driverId}
  Future<Result<RawJson>> getRemaining(DriverId driverId);
}

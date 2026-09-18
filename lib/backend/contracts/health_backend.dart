import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class HealthBackend {
  /// GET /eld/health
  Future<Result<void>> checkLiveness();

  /// GET /eld/health/detailed
  Future<Result<RawJson>> checkDetailed();
}

import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class RulesScreenBackend {
  /// GET /eld/rules-screen
  // TODO(P2): replace with RulesScreen
  Future<Result<RawJson>> getRulesScreen({DriverId? driverId});

  /// PUT /eld/rules-screen
  // TODO(P2): replace with RulesScreen
  Future<Result<RawJson>> saveRulesScreen(RawJson settings);
}

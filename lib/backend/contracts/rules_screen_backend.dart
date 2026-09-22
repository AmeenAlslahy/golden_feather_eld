import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';
import '../../features/account/domain/entities/rules_screen_model.dart';
import 'raw_json.dart';

abstract interface class RulesScreenBackend {
  /// GET /eld/rules-screen
  Future<Result<RulesScreenModel>> getRulesScreen({DriverId? driverId});

  /// PUT /eld/rules-screen
  Future<Result<RulesScreenModel>> saveRulesScreen({
    required DriverId driverId,
    required RawJson update,
  });
}

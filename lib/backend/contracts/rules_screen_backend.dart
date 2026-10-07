import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
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

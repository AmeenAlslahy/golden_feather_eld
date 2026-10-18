import '../../../../backend/contracts/rules_screen_backend.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../models/rules_screen_model.dart';
import '../models/rules_screen_update_request.dart';

class UpdateRulesUseCase {
  final RulesScreenBackend _backend;
  final LocalStorageService _storage;

  UpdateRulesUseCase(this._backend, this._storage);

  Future<Result<RulesScreenModel>> execute({
    required DriverId driverId,
    required RulesScreenUpdateRequest request,
  }) async {
    final result = await _backend.saveRulesScreen(
      driverId: driverId,
      update: request.toJson(),
    );

    final model = result.valueOrNull;
    if (model != null) {
      final currentConfig = _storage.hosConfiguration;
      final newLimits = model.limits;

      final mergedConfig = currentConfig.copyWith(
        drivingLimitMinutes: newLimits.drivingLimitMinutes,
        shiftLimitMinutes: newLimits.shiftLimitMinutes,
        cycleLimitHours: newLimits.cycleLimitHours,
        maxConsecutiveDays: newLimits.maxConsecutiveDays,
      );

      await _storage.setHosConfiguration(mergedConfig);
    }

    return result;
  }
}

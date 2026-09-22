import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';
import '../../../../backend/contracts/rules_screen_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../entities/rules_screen_model.dart';

class UpdateRulesUseCase {
  final RulesScreenBackend _backend;
  final LocalStorageService _storage;
  final String _driverId;

  UpdateRulesUseCase(this._backend, this._storage, this._driverId);

  Future<Result<RulesScreenModel>> execute(RulesScreenUpdateRequest request) async {
    // 1. Call backend to update
    final result = await _backend.saveRulesScreen(
      driverId: DriverId(int.tryParse(_driverId) ?? 0),
      update: request.toJson(),
    );

    return result.mapValue((model) {
      // 2. Pessimistic update: only update local storage if the server succeeds.
      final currentConfig = _storage.hosConfiguration;
      final newLimits = model.limits;

      // 3. Merge Matrix: preserve critical local fields while applying server limits
      final mergedConfig = currentConfig.copyWith(
        drivingLimitMinutes: newLimits.drivingLimitMinutes,
        shiftLimitMinutes: newLimits.shiftLimitMinutes,
        cycleLimitHours: newLimits.cycleLimitHours,
        maxConsecutiveDays: newLimits.maxConsecutiveDays,
        // The following fields are NOT provided by the backend limits, so we PRESERVE CURRENT:
        // breakDurationMinutes: currentConfig.breakDurationMinutes,
        // movingSpeedThresholdKmh: currentConfig.movingSpeedThresholdKmh,
        // driveBeforeBreakMinutes: currentConfig.driveBeforeBreakMinutes,
        // weeklyRestartHours: currentConfig.weeklyRestartHours,
      );

      // 4. Save to local storage
      _storage.setHosConfiguration(mergedConfig);

      return model;
    });
  }
}

final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase>((ref) {
  final backend = ref.watch(rulesScreenBackendProvider);
  final storage = ref.watch(localStorageProvider);
  final user = ref.watch(authStateProvider).user;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }

  return UpdateRulesUseCase(backend, storage, user.id);
});

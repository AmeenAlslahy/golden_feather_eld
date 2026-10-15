import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/rules_screen_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/result/result.dart';
import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../models/rules_screen_model.dart';

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

    final model = result.valueOrNull;
    if (model != null) {
      // 2. Pessimistic update: only update local storage if the server succeeds.
      final currentConfig = _storage.hosConfiguration;
      final newLimits = model.limits;

      // 3. Merge Matrix: preserve critical local fields while applying server limits
      final mergedConfig = currentConfig.copyWith(
        drivingLimitMinutes: newLimits.drivingLimitMinutes,
        shiftLimitMinutes: newLimits.shiftLimitMinutes,
        cycleLimitHours: newLimits.cycleLimitHours,
        maxConsecutiveDays: newLimits.maxConsecutiveDays,
      );

      // 4. Save to local storage asynchronously and awaited
      await _storage.setHosConfiguration(mergedConfig);
    }

    return result;
  }
}

final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase?>((ref) {
  final backend = ref.watch(rulesScreenBackendProvider);
  final storage = ref.watch(localStorageProvider);
  final user = ref.watch(authStateProvider).user;
  
  if (user == null) {
    return null;
  }

  return UpdateRulesUseCase(backend, storage, user.id);
});

import '../../../../backend/contracts/rules_screen_backend.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../application/models/rules_screen_model.dart';
import '../../application/models/rules_screen_update_request.dart';
import '../datasources/rules_screen_local_cache.dart';

class RulesScreenRepository {
  final RulesScreenBackend _backend;
  final RulesScreenLocalCache _cache;

  RulesScreenRepository(this._backend, this._cache);

  Future<Result<RulesScreenModel>> getRulesScreen({DriverId? driverId}) async {
    final result = await _backend.getRulesScreen(driverId: driverId);

    return result.fold(
      (failure) {
        if (_isOfflineFailure(failure)) {
          final cached = _cache.loadRulesScreen(driverId: driverId);
          if (cached != null) return ok(cached);
        }
        return err(failure);
      },
      (model) async {
        await _cache.saveRulesScreen(model, driverId: driverId);
        return ok(model);
      },
    );
  }

  Future<Result<RulesScreenModel>> saveRulesScreen({
    required DriverId driverId,
    required RulesScreenUpdateRequest request,
  }) async {
    final result = await _backend.saveRulesScreen(
      driverId: driverId,
      update: request.toJson(),
    );

    return result.fold(
      (failure) => err(failure),
      (model) async {
        await _cache.saveRulesScreen(model, driverId: driverId);
        return ok(model);
      },
    );
  }

  static bool _isOfflineFailure(AppError failure) {
    return failure is NetworkError ||
        failure.l10nKey == 'errNoInternet' ||
        failure.code.startsWith('network') ||
        failure.code.contains('timeout') ||
        failure.code.contains('offline');
  }
}

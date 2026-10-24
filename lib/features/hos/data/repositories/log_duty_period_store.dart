import '../../../../core/domain/entities/hos_models.dart';
import '../../../logs/domain/repositories/log_repository.dart';
import '../../domain/repositories/duty_period_store.dart';

class LogDutyPeriodStore implements DutyPeriodStore {
  final LogRepository _repository;

  const LogDutyPeriodStore(this._repository);

  @override
  Future<List<DutyPeriod>> getPeriods(DateTime date) async {
    final result = await _repository.getPeriods(date);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (periods) => periods,
    );
  }

  @override
  Future<void> savePeriod(DutyPeriod period) async {
    final result = await _repository.savePeriod(period);
    result.fold((failure) => throw StateError(failure.message), (_) {});
  }
}

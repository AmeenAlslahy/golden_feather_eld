import '../../../../core/domain/entities/hos_models.dart';

abstract class DutyPeriodStore {
  Future<List<DutyPeriod>> getPeriods(DateTime date);

  Future<void> savePeriod(DutyPeriod period);
}

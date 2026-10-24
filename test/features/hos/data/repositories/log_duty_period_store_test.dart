import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/log_duty_period_store.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';

class _FakeLogRepository implements LogRepository {
  Either<Failure, List<DutyPeriod>> periodsResult = const Right(<DutyPeriod>[]);

  Either<Failure, bool> saveResult = const Right(true);

  final List<DutyPeriod> saved = [];

  @override
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date) async {
    return periodsResult;
  }

  @override
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period) async {
    saved.add(period);
    return saveResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeLogRepository repository;
  late LogDutyPeriodStore store;

  setUp(() {
    repository = _FakeLogRepository();
    store = LogDutyPeriodStore(repository);
  });

  test('reads periods through the log repository', () async {
    final period = DutyPeriod(
      status: 'driving',
      startTime: DateTime.utc(2026, 3, 1, 8),
      endTime: DateTime.utc(2026, 3, 1, 9),
    );
    repository.periodsResult = Right([period]);

    expect(await store.getPeriods(DateTime.utc(2026, 3, 1)), [period]);
  });

  test('saves periods through the log repository', () async {
    final period = DutyPeriod(
      status: 'on_duty',
      startTime: DateTime.utc(2026, 3, 1, 9),
      endTime: DateTime.utc(2026, 3, 1, 10),
    );

    await store.savePeriod(period);

    expect(repository.saved, [period]);
  });

  test('throws when the log repository rejects a save', () async {
    repository.saveResult = const Left(CacheFailure(message: 'disk full'));

    expect(
      () => store.savePeriod(
        DutyPeriod(
          status: 'off_duty',
          startTime: DateTime.utc(2026, 3, 1, 10),
          endTime: DateTime.utc(2026, 3, 1, 11),
        ),
      ),
      throwsStateError,
    );
  });
}

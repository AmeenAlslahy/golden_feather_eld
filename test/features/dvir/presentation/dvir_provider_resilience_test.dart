import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_defect.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/dvir/domain/repositories/dvir_repository.dart';
import 'package:golden_feather_eld/features/dvir/presentation/providers/dvir_provider.dart';

DvirReport _report(String id, String vehicleId, {bool reviewed = false}) {
  return DvirReport(
    id: id,
    type: InspectionType.preTrip,
    date: DateTime.utc(2026, 10, 14),
    driverName: 'Driver',
    vehicleId: vehicleId,
    nextDriverReviewed: reviewed,
  );
}

class _FakeRepository implements DvirRepository {
  Either<Failure, List<DvirReport>> listResult =
      const Right<Failure, List<DvirReport>>([]);
  Either<Failure, DvirReport?> previousResult =
      const Right<Failure, DvirReport?>(null);
  Either<Failure, bool> submitResult = const Right<Failure, bool>(true);
  Either<Failure, bool> reviewResult = const Right<Failure, bool>(true);

  bool throwOnSubmit = false;
  bool throwOnReview = false;
  bool throwOnList = false;

  final Map<String, Completer<Either<Failure, DvirReport?>>> previousByVehicle =
      {};
  final Map<String, Completer<Either<Failure, DvirReport>>> detailsById = {};
  final List<String> listRequests = [];
  final List<String> detailRequests = [];

  @override
  Future<Either<Failure, List<DvirReport>>> getDvirReports(
    String vehicleId,
  ) async {
    listRequests.add(vehicleId);
    if (throwOnList) throw StateError('list blew up');
    return listResult;
  }

  @override
  Future<Either<Failure, DvirReport?>> getPreviousDvir(String vehicleId) {
    final controlled = previousByVehicle[vehicleId];
    if (controlled != null) return controlled.future;
    return Future.value(previousResult);
  }

  @override
  Future<Either<Failure, DvirReport>> getDvirDetails(String id) {
    detailRequests.add(id);
    final controlled = detailsById[id];
    if (controlled != null) return controlled.future;
    return Future.value(const Left(ServerFailure(message: 'not used')));
  }

  @override
  Future<Either<Failure, List<DvirCatalogItem>>> getDefectsCatalog() async =>
      const Right<Failure, List<DvirCatalogItem>>([]);

  @override
  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
  }) async {
    if (throwOnSubmit) throw StateError('queue blew up');
    return submitResult;
  }

  @override
  Future<Either<Failure, bool>> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async {
    if (throwOnReview) throw StateError('review blew up');
    return reviewResult;
  }

  @override
  Future<Either<Failure, DvirDefect>> getDefectDetails(int defectId) async =>
      const Left(ServerFailure(message: 'not used'));

  @override
  Future<Either<Failure, List<DvirDefect>>> getActiveDefects({
    required String uniqueId,
  }) async => const Right<Failure, List<DvirDefect>>([]);
}

void main() {
  late _FakeRepository repository;
  late DvirNotifier notifier;

  setUp(() {
    repository = _FakeRepository();
    notifier = DvirNotifier(repository: repository);
  });

  tearDown(() => notifier.dispose());

  group('§396.13 previous lookup', () {
    test('unknown offline answer is not accepted as "no previous"', () async {
      repository.previousResult = const Left(NetworkFailure());

      expect(await notifier.ensurePreviousDvir('TRK-1'), isFalse);
      expect(notifier.state.previousLookupDone, isTrue);
      expect(notifier.state.previousLookupFailed, isTrue);
    });

    test('an authoritative "no previous" answer is accepted', () async {
      repository.previousResult = const Right<Failure, DvirReport?>(null);

      expect(await notifier.ensurePreviousDvir('TRK-1'), isTrue);
      expect(notifier.state.previousToReview('TRK-1'), isNull);
    });

    test('a previously loaded vehicle list is a valid fallback', () async {
      repository.previousResult = const Left(NetworkFailure());
      notifier.state = notifier.state.copyWith(
        reports: [_report('7', 'TRK-1')],
      );

      expect(await notifier.ensurePreviousDvir('TRK-1'), isTrue);
      expect(notifier.state.previousToReview('TRK-1')?.id, '7');
    });

    test('a successfully loaded empty list answers "no previous"', () async {
      repository.previousResult = const Left(NetworkFailure());
      final loadedNotifier = DvirNotifier(
        repository: repository,
        vehicleId: 'TRK-1',
      );
      addTearDown(loadedNotifier.dispose);
      await loadedNotifier.refresh();

      expect(loadedNotifier.state.reportsLoaded, isTrue);
      expect(await loadedNotifier.ensurePreviousDvir('TRK-1'), isTrue);
      expect(loadedNotifier.state.previousToReview('TRK-1'), isNull);
    });

    test('submit waits for an in-flight lookup', () async {
      final completer = Completer<Either<Failure, DvirReport?>>();
      repository.previousByVehicle['TRK-1'] = completer;

      final pending = notifier.ensurePreviousDvir('TRK-1');
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.previousLookupDone, isFalse);

      completer.complete(const Right<Failure, DvirReport?>(null));
      expect(await pending, isTrue);
    });

    test(
      'a stale answer for an older vehicle cannot overwrite the newer one',
      () async {
        final first = Completer<Either<Failure, DvirReport?>>();
        final second = Completer<Either<Failure, DvirReport?>>();
        repository.previousByVehicle['TRK-A'] = first;
        repository.previousByVehicle['TRK-B'] = second;

        final loadA = notifier.loadPreviousDvir('TRK-A');
        final loadB = notifier.loadPreviousDvir('TRK-B');

        second.complete(const Right<Failure, DvirReport?>(null));
        await loadB;
        first.complete(Right<Failure, DvirReport?>(_report('90', 'TRK-A')));
        await loadA;

        expect(notifier.state.previousVehicleId, 'TRK-B');
        expect(notifier.state.previousDvir, isNull);
      },
    );
  });

  group('detail request fencing', () {
    test('a stale detail response cannot replace the newer report', () async {
      final first = Completer<Either<Failure, DvirReport>>();
      final second = Completer<Either<Failure, DvirReport>>();
      repository.detailsById['1'] = first;
      repository.detailsById['2'] = second;

      final loadFirst = notifier.loadDvirDetails('1');
      final loadSecond = notifier.loadDvirDetails('2');

      second.complete(Right<Failure, DvirReport>(_report('2', 'TRK-1')));
      await loadSecond;
      first.complete(Right<Failure, DvirReport>(_report('1', 'TRK-1')));
      await loadFirst;

      expect(notifier.state.currentReport?.id, '2');
      expect(notifier.state.error, isNull);
    });

    test('a stale detail failure cannot clear the newer report', () async {
      final first = Completer<Either<Failure, DvirReport>>();
      final second = Completer<Either<Failure, DvirReport>>();
      repository.detailsById['1'] = first;
      repository.detailsById['2'] = second;

      final loadFirst = notifier.loadDvirDetails('1');
      final loadSecond = notifier.loadDvirDetails('2');

      second.complete(Right<Failure, DvirReport>(_report('2', 'TRK-1')));
      await loadSecond;
      first.complete(const Left(ServerFailure(message: 'stale failure')));
      await loadFirst;

      expect(notifier.state.currentReport?.id, '2');
      expect(notifier.state.error, isNull);
    });
  });

  group('review state', () {
    test(
      'a successful review satisfies the previous report for this session',
      () async {
        notifier.state = notifier.state.copyWith(
          previousDvir: _report('7', 'TRK-1'),
          previousVehicleId: 'TRK-1',
          previousLookupDone: true,
          reports: [_report('7', 'TRK-1')],
        );
        expect(notifier.state.previousToReview('TRK-1')?.id, '7');

        final error = await notifier.reviewDvir(
          dvirId: '7',
          reviewingDriverId: 2,
          reviewingDriverName: 'Next Driver',
          signatureData: 'AQID',
          driverAgreed: true,
        );

        expect(error, isNull);
        expect(notifier.state.previousToReview('TRK-1'), isNull);
        expect(notifier.state.reports.single.nextDriverReviewed, isTrue);
        expect(notifier.state.isSubmitting, isFalse);
      },
    );
  });

  group('submission/lookup resilience', () {
    test(
      'a thrown submission resets isSubmitting and reports failure',
      () async {
        repository.throwOnSubmit = true;

        final saved = await notifier.createReport(
          _report('', 'TRK-1'),
          driverId: 1,
        );

        expect(saved, isFalse);
        expect(notifier.state.isSubmitting, isFalse);
        expect(notifier.state.error, isNotNull);
      },
    );

    test('a thrown review resets isSubmitting and reports failure', () async {
      repository.throwOnReview = true;

      final error = await notifier.reviewDvir(
        dvirId: '9',
        reviewingDriverId: 1,
        reviewingDriverName: 'Driver',
        signatureData: 'AQID',
        driverAgreed: true,
      );

      expect(error, isNotNull);
      expect(notifier.state.isSubmitting, isFalse);
    });

    test('a thrown list load clears the loading flag', () async {
      repository.throwOnList = true;
      final loadingNotifier = DvirNotifier(
        repository: repository,
        vehicleId: 'TRK-1',
      );
      await loadingNotifier.refresh();

      expect(loadingNotifier.state.isLoading, isFalse);
      expect(loadingNotifier.state.error, isNotNull);

      loadingNotifier.dispose();
    });

    test(
      'setVehicle switches the list source and drops the old answer',
      () async {
        repository.listResult = Right<Failure, List<DvirReport>>([
          _report('1', 'TRK-A'),
        ]);
        final switching = DvirNotifier(
          repository: repository,
          vehicleId: 'TRK-A',
        );
        addTearDown(switching.dispose);
        await switching.refresh();
        expect(switching.state.reports.single.vehicleId, 'TRK-A');

        repository.listResult = Right<Failure, List<DvirReport>>([
          _report('2', 'TRK-B'),
        ]);
        await switching.setVehicle('TRK-B');

        expect(repository.listRequests, containsAllInOrder(['TRK-A', 'TRK-B']));
        expect(switching.state.reports.single.vehicleId, 'TRK-B');
        expect(switching.state.reportsLoaded, isTrue);
      },
    );
  });
}

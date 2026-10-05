import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/inspection/data/providers/inspection_repository_providers.dart';
import 'package:golden_feather_eld/features/inspection/domain/repositories/inspection_repository.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/inspection_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepository extends Mock implements InspectionRepository {}

class _FakeStorage extends Mock implements LocalStorageService {
  @override
  String get language => 'en';
}

/// Invariants under test (state behaviour, not implementation):
/// 1. successful start selects day 0 with its own log;
/// 2. while a day load is in flight the displayed pair never changes,
///    and success commits index+log together;
/// 3. a failed day load keeps the displayed pair and sets dayError;
/// 4. an in-flight selectDay quietly rejects a second request;
/// 5. a response whose date is not the requested day is never committed;
/// 6. out-of-bounds indices make no request;
/// 7. endInspection resets the day-selection state.
void main() {
  late _MockRepository repo;
  late ProviderContainer container;

  final d0 = DateTime.utc(2026, 1, 13);
  final d1 = DateTime.utc(2026, 1, 12);
  final d2 = DateTime.utc(2026, 1, 11);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(const DriverId(101));
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _MockRepository();
    container = ProviderContainer(
      overrides: [
        inspectionRepositoryProvider.overrideWithValue(repo),
        currentDriverIdProvider.overrideWithValue(101),
        localStorageProvider.overrideWithValue(_FakeStorage()),
      ],
    );
    addTearDown(container.dispose);
    when(
      () => repo.getCycle(
        driverId: any(named: 'driverId'),
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => Right([_day(d0), _day(d1), _day(d2)]));
    when(
      () => repo.getLogs(
        driverId: any(named: 'driverId'),
        date: any(named: 'date'),
      ),
    ).thenAnswer((inv) async {
      final date = inv.namedArguments[#date] as DateTime?;
      return Right(_log(date ?? d0));
    });
    // بدء التفتيش يسجّل القفل على الخادم (غير معيق) — نجاح صامت هنا.
    when(
      () => repo.registerInspectionStart(
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  InspectionNotifier notifier() => container.read(inspectionProvider.notifier);
  InspectionState state() => container.read(inspectionProvider);

  test('TEST 1: successful start selects day 0 with its own log', () async {
    await notifier().startInspection(pin: '1234');

    final s = state();
    expect(s.isInspectionMode, isTrue);
    expect(s.selectedDayIndex, 0);
    expect(s.isDayLoading, isFalse);
    expect(s.dayError, isNull);
    expect(_sameDay(s.log!.logDate, s.cycle[0].logDate), isTrue);
  });

  test(
    'TEST 2: in-flight keeps the old pair; success commits index+log together',
    () async {
      await notifier().startInspection(pin: '1234');
      final oldLog = state().log;

      final gate = Completer<Either<Failure, DotInspectionLog>>();
      when(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) => gate.future);

      final pending = notifier().selectDay(1);
      expect(state().isDayLoading, isTrue);
      expect(state().selectedDayIndex, 0);
      expect(identical(state().log, oldLog), isTrue);

      gate.complete(Right(_log(d1)));
      await pending;

      final s = state();
      expect(s.isDayLoading, isFalse);
      expect(s.selectedDayIndex, 1);
      expect(_sameDay(s.log!.logDate, d1), isTrue);
      expect(s.dayError, isNull);
    },
  );

  test(
    'TEST 3: failed day load keeps the displayed pair and sets dayError',
    () async {
      await notifier().startInspection(pin: '1234');
      final oldLog = state().log;
      when(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'boom')));

      await notifier().selectDay(1);

      final s = state();
      expect(s.isDayLoading, isFalse);
      expect(s.selectedDayIndex, 0);
      expect(identical(s.log, oldLog), isTrue);
      expect(s.dayError, isNotNull);

      // Retry (case B: a new selection clears dayError immediately) that
      // succeeds (case C: dayError stays null afterwards).
      when(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => Right(_log(d2)));
      await notifier().selectDay(2);
      final s2 = state();
      expect(s2.dayError, isNull);
      expect(s2.selectedDayIndex, 2);
      expect(_sameDay(s2.log!.logDate, d2), isTrue);
    },
  );

  test(
    'TEST 4: an in-flight selectDay quietly rejects a second request',
    () async {
      await notifier().startInspection(pin: '1234');

      final gate = Completer<Either<Failure, DotInspectionLog>>();
      when(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) => gate.future);

      final first = notifier().selectDay(1);
      final second = notifier().selectDay(2); // rejected while loading

      gate.complete(Right(_log(d1)));
      await first;
      await second;

      // getLogs: once for the start flow + once for selectDay(1) only.
      verify(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).called(2);
      expect(state().selectedDayIndex, 1);
      expect(state().isDayLoading, isFalse);
    },
  );

  test(
    'TEST 5: a response for a different day is refused — no commit, no fallback',
    () async {
      await notifier().startInspection(pin: '1234');
      final oldLog = state().log;
      when(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => Right(_log(DateTime.utc(2025, 5, 5))));

      await notifier().selectDay(1);

      final s = state();
      expect(s.isDayLoading, isFalse);
      expect(s.selectedDayIndex, 0);
      expect(identical(s.log, oldLog), isTrue);
      expect(s.dayError, isNotNull);
    },
  );

  test(
    'TEST 6: out-of-bounds index makes no request and changes nothing',
    () async {
      await notifier().startInspection(pin: '1234');

      await notifier().selectDay(-1);
      await notifier().selectDay(3);

      verify(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).called(1); // the start flow only
      expect(state().selectedDayIndex, 0);
      expect(state().isDayLoading, isFalse);
    },
  );

  test('TEST 7: endInspection resets day-selection state', () async {
    await notifier().startInspection(pin: '1234');
    await notifier().selectDay(1);

    notifier().endInspection();

    final s = state();
    expect(s.isInspectionMode, isFalse);
    expect(s.selectedDayIndex, 0);
    expect(s.isDayLoading, isFalse);
    expect(s.dayError, isNull);
    expect(s.cycle, isEmpty);
    expect(s.log, isNull);
  });

  test(
    'TEST 9: initial log failure refuses locked mode (startup atomicity)',
    () async {
      when(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'log fail')));

      await notifier().startInspection(pin: '1234');

      final s = state();
      expect(s.isInspectionMode, isFalse);
      expect(s.isPinLocked, isFalse);
      expect(s.error, isNotNull);
      expect(s.log, isNull);
    },
  );

  test(
    'TEST 8: empty cycle — selectDay is a safe no-op with no request',
    () async {
      // No startInspection: cycle is empty and driverId is 0 is impossible
      // here, so the bounds guard must reject before any state write.
      await notifier().selectDay(0);

      verifyNever(
        () => repo.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      );
      final s = state();
      expect(s.isDayLoading, isFalse);
      expect(s.dayError, isNull);
      expect(s.log, isNull);
      expect(s.selectedDayIndex, 0);
    },
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DotInspectionCycleDay _day(DateTime date) => DotInspectionCycleDay(
  driverId: const DriverId(101),
  driverName: 'Ahmed',
  logDate: date,
  displayDate: 'Day ${date.day}',
  displayLocation: 'Riyadh',
  certified: false,
  certifiedAt: null,
  eldRegistrationId: 'GF10000001',
  eldIdentifier: 'GF-ELD-001',
  eldProvider: 'Golden Feather',
  vehicleNumber: '646',
  uniqueId: '1001',
  vin: '1FUJGLDR5CSBJ0527',
  startOdometerKm: 1,
  endOdometerKm: 2,
  totalDistanceKm: 1,
  engineHours: 1,
  trailers: '',
  shippingDocuments: '',
  carrierName: 'Golden Feather Transport',
  usdotNumber: '1234567',
  mainOfficeAddress: 'M',
  homeTerminalAddress: 'H',
  activeDataDiagnostics: const [],
  activeDeviceMalfunctions: const [],
  exemptDriver: false,
  hasUnidentifiedDriving: false,
  unidentifiedDrivingCount: 0,
);

DotInspectionLog _log(DateTime date) => DotInspectionLog(
  driverId: const DriverId(101),
  driverName: 'Ahmed',
  logDate: date,
  displayDate: 'Day ${date.day}',
  displayLocation: 'Riyadh',
  certified: false,
  certifiedAt: null,
  eldRegistrationId: 'GF10000001',
  eldIdentifier: 'GF-ELD-001',
  eldProvider: 'Golden Feather',
  vehicleNumber: '646',
  uniqueId: '1001',
  vin: '1FUJGLDR5CSBJ0527',
  startOdometerKm: 1,
  endOdometerKm: 2,
  totalDistanceKm: 1,
  engineHours: 1,
  trailers: '',
  shippingDocuments: '',
  carrierName: 'Golden Feather Transport',
  usdotNumber: '1234567',
  mainOfficeAddress: 'M',
  homeTerminalAddress: 'H',
  activeDataDiagnostics: const [],
  activeDeviceMalfunctions: const [],
  events: const [],
  readOnly: false,
);

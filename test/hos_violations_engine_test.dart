import 'package:golden_feather_eld/features/hos/domain/engine/hos_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_violations_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/data/datasources/hos_local_data_source.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';

class MockDutyStatusTracker extends Mock implements DutyStatusTracker {}

class MockHosLocalDataSource extends Mock implements HosLocalDataSource {}

class MockHosConfiguration extends Mock implements HosConfiguration {}

void main() {
  late HosViolationsEngine engine;
  late MockDutyStatusTracker mockTracker;
  late MockHosLocalDataSource mockDb;
  late MockHosConfiguration mockConfig;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockTracker = MockDutyStatusTracker();
    mockDb = MockHosLocalDataSource();
    mockConfig = MockHosConfiguration();

    when(() => mockTracker.getTodayStats()).thenReturn(
        {'driving': 0.0, 'on_duty': 0.0, 'off_duty': 0.0, 'sleeper': 0.0});
    when(() => mockTracker.getWeekStats()).thenReturn(
        {'driving': 0.0, 'work': 0.0, 'rest': 0.0, 'distance': 0.0});
    when(() => mockTracker.periods).thenReturn([]);
    when(() => mockConfig.cycleLimitHours).thenReturn(70);

    when(() => mockDb.saveViolation(any())).thenAnswer((_) async => true);
    engine = HosViolationsEngine(mockTracker, mockDb, mockConfig,
        FakeTrustedTimeProvider(initialUtcTime: DateTime.now().toUtc()));
  });

  tearDown(() {
    engine.dispose();
  });

  group('HOS Violations Engine Tests', () {
    test('checkAll should return no violations for compliant data', () {
      final violations = engine.checkAll(
        drivingHoursToday: 8.0,
        workHoursToday: 10.0,
        restHoursToday: 14.0,
        drivingHoursWeek: 40.0,
        consecutiveDays: 5,
        hasBreak: true,
        hasWeeklyRestart: true,
        now: DateTime.now(),
      );

      expect(violations, isEmpty);
    });

    test('checkAll should detect daily driving limit exceeded', () {
      final violations = engine.checkAll(
        drivingHoursToday: 12.0, // > 11
        workHoursToday: 13.0,
        restHoursToday: 11.0,
        drivingHoursWeek: 40.0,
        consecutiveDays: 5,
        hasBreak: true,
        hasWeeklyRestart: true,
        now: DateTime.now(),
      );

      expect(violations.isNotEmpty, true);
      expect(violations.first.type, HosViolationType.dailyDrivingExceeded);
    });

    test('checkAll should detect 14-hour work limit exceeded', () {
      final violations = engine.checkAll(
        drivingHoursToday: 10.0,
        workHoursToday: 15.0, // > 14
        restHoursToday: 9.0,
        drivingHoursWeek: 40.0,
        consecutiveDays: 5,
        hasBreak: true,
        hasWeeklyRestart: true,
        now: DateTime.now(),
      );

      expect(
          violations.any((v) => v.type == HosViolationType.dailyWorkExceeded),
          true);
    });

    test('checkAll should detect consecutive days exceeded', () {
      final violations = engine.checkAll(
        drivingHoursToday: 5.0,
        workHoursToday: 8.0,
        restHoursToday: 16.0,
        drivingHoursWeek: 65.0,
        consecutiveDays: 8, // > 7
        hasBreak: true,
        hasWeeklyRestart: true,
        now: DateTime.now(),
      );

      expect(
          violations
              .any((v) => v.type == HosViolationType.consecutiveDaysExceeded),
          true);
    });
  });
}

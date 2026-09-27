import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockLogRepository extends Mock implements LogRepository {}

class _FakeLogEvent extends Fake implements LogEvent {}

/// SRS 5.2 — opening a day from the list must load that day's duty-status
/// events (the list endpoint carries none). Regression for "events / graph
/// never shown".
void main() {
  late _MockLogRepository repo;
  late ProviderContainer container;

  final day = DailyLog(
    id: const DailyLogId(42),
    date: DateTime(2026, 9, 24),
    totalDrivingHours: 0,
    isFormComplete: false,
    isCertified: false,
  );

  LogEvent ev(String id, String status, int minutes) => LogEvent(
        id: id,
        status: status,
        statusArabic: status,
        startTime: DateTime(2026, 9, 24, 8),
        duration: Duration(minutes: minutes),
        location: 'x',
      );

  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(_FakeLogEvent());
  });

  setUp(() {
    repo = _MockLogRepository();
    when(() => repo.getDailyLogs(
          driverId: any(named: 'driverId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => Right([day]));
    container = ProviderContainer(overrides: [
      logRepositoryProvider.overrideWithValue(repo),
      currentDriverIdProvider.overrideWithValue(106),
    ]);
    addTearDown(container.dispose);
  });

  test('selectLog fetches events for that log id and fills selectedLog',
      () async {
    when(() => repo.getEvents(any(), any())).thenAnswer(
        (_) async => Right([ev('1', 'OFF', 480), ev('2', 'D', 120)]));

    final notifier = container.read(logsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    notifier.selectLog(day);
    expect(container.read(logsProvider).isLoadingEvents, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(logsProvider);
    expect(state.isLoadingEvents, isFalse);
    expect(state.eventsError, isNull);
    expect(state.selectedLog!.events.map((e) => e.status), ['OFF', 'D']);
    // The list copy is kept in sync (single source of truth).
    expect(state.logs.single.events.length, 2);
    verify(() => repo.getEvents(const DailyLogId(42), day.date)).called(1);
  });

  test('failure is exposed as eventsError and retry reloads', () async {
    var calls = 0;
    when(() => repo.getEvents(any(), any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Left(ServerFailure(message: 'boom', statusCode: 500));
      }
      return Right([ev('1', 'ON', 60)]);
    });

    final notifier = container.read(logsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    notifier.selectLog(day);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(logsProvider).eventsError, 'boom');
    expect(container.read(logsProvider).selectedLog!.events, isEmpty);

    await notifier.loadSelectedLogEvents();

    final state = container.read(logsProvider);
    expect(state.eventsError, isNull);
    expect(state.selectedLog!.events.single.status, 'ON');
  });

  test('updateEvent forwards the mandatory reason and refreshes from server',
      () async {
    when(() => repo.getEvents(any(), any()))
        .thenAnswer((_) async => Right([ev('7', 'OFF', 60)]));
    when(() => repo.updateEvent(any(), reason: any(named: 'reason')))
        .thenAnswer((_) async => const Right(true));

    final notifier = container.read(logsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    notifier.selectLog(day);
    await Future<void>.delayed(Duration.zero);

    final ok = await notifier.updateEvent(ev('7', 'SB', 60),
        reason: 'Wrong status selected');
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    verify(() =>
            repo.updateEvent(any(), reason: 'Wrong status selected'))
        .called(1);
    // Initial load + refresh after the edit.
    verify(() => repo.getEvents(any(), any())).called(2);
  });
}

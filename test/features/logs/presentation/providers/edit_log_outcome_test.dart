import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/core/time/time_authority_provider.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockLogsNotifier extends StateNotifier<LogsState>
    with Mock
    implements LogsNotifier {
  MockLogsNotifier(super.state);
}

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async => true;
  @override
  void forceLogout() {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> checkAuthStatus() async {}
  @override
  void clearError() {}
}

class MockTimeAuthority extends Mock implements TimeAuthority {}

class MockLogRepository extends Mock implements LogRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AuditEntry(
        id: 'aud-1',
        timestamp: DateTime.utc(2026, 1, 1),
        driverId: 'driver-101',
        newStatus: 'ON',
        reason: 'test',
      ),
    );
  });

  group('EditLogOutcomeType Direct Mapping & Semantics', () {
    // offlineQueued means the edit is in the offline queue — it has NOT been
    // confirmed by the server. The UI shows a 'will sync' message, NOT a success message.
    test('pendingSync maps to offlineQueued', () {
      final persisted = LogEvent(
        id: 'e1',
        status: 'ON',
        startTime: DateTime.utc(2026, 1, 1, 8, 0),
        duration: const Duration(hours: 1),
        location: 'Dallas',
        syncStatus: EventSyncStatus.pendingSync,
      );

      final EditLogOutcomeType outcomeType =
          persisted.syncStatus == EventSyncStatus.pendingSync
          ? EditLogOutcomeType.offlineQueued
          : EditLogOutcomeType.confirmed;

      expect(outcomeType, EditLogOutcomeType.offlineQueued);
    });

    // unconfirmed means HTTP 200 was received but the server did not echo a
    // parseable event. The local state is updated optimistically. The user is informed this is unconfirmed.
    test('null persisted event maps to unconfirmed', () {
      const LogEvent? persisted = null;

      final outcomeType = persisted == null
          ? EditLogOutcomeType.unconfirmed
          : (persisted.syncStatus == EventSyncStatus.pendingSync
                ? EditLogOutcomeType.offlineQueued
                : EditLogOutcomeType.confirmed);

      expect(outcomeType, EditLogOutcomeType.unconfirmed);
    });

    test('none syncStatus maps to confirmed', () {
      final persisted = LogEvent(
        id: 'e1',
        status: 'OFF',
        startTime: DateTime.utc(2026, 1, 1, 9, 0),
        duration: const Duration(hours: 1),
        location: 'Dallas',
        syncStatus: EventSyncStatus.none,
      );

      final outcomeType = persisted.syncStatus == EventSyncStatus.pendingSync
          ? EditLogOutcomeType.offlineQueued
          : EditLogOutcomeType.confirmed;

      expect(outcomeType, EditLogOutcomeType.confirmed);
    });
  });

  group('EditLogNotifier Outcome Classification Integration', () {
    late MockLogsNotifier mockLogsNotifier;
    late MockAuthNotifier mockAuthNotifier;
    late MockTimeAuthority mockTimeAuth;
    late MockLogRepository mockRepo;
    late ProviderContainer container;

    final existingEvent = LogEvent(
      id: 'e1',
      status: 'ON',
      startTime: DateTime(2026, 1, 1, 8, 0),
      duration: const Duration(hours: 1),
      location: 'Dallas, TX',
      originalLatitude: 32.77,
      originalLongitude: -96.79,
    );

    final testLog = DailyLog(
      id: const DailyLogId(1),
      uniqueId: 'LOG-1',
      date: DateTime(2026, 1, 1),
      formattedTotalWorkTime: '10h',
      totalDrivingHours: 5.0,
      isFormComplete: true,
      isCertified: false,
      events: [existingEvent],
    );

    final testUser = User(
      id: 'driver-101',
      username: 'driver1',
      email: 'driver@carrier.com',
      fullName: 'Test Driver',
      role: UserRole.fieldWorker,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      mockLogsNotifier = MockLogsNotifier(
        LogsState(logs: [testLog], selectedLog: testLog, isLoading: false),
      );

      mockAuthNotifier = MockAuthNotifier(
        AuthState(status: AuthStatus.authenticated, user: testUser),
      );

      mockTimeAuth = MockTimeAuthority();
      when(
        () => mockTimeAuth.nowUtc(),
      ).thenReturn(DateTime.utc(2026, 1, 1, 10, 0, 0));

      mockRepo = MockLogRepository();
      when(
        () => mockRepo.logAudit(any()),
      ).thenAnswer((_) async => const Right(true));

      registerFallbackValue(existingEvent);

      container = ProviderContainer(
        overrides: [
          logsProvider.overrideWith((ref) => mockLogsNotifier),
          authStateProvider.overrideWith((ref) => mockAuthNotifier),
          timeAuthorityProvider.overrideWithValue(mockTimeAuth),
          logRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'Right(null) → unconfirmed (server accepted but no echo — local save only, NOT server-confirmed)',
      () async {
        // unconfirmed means HTTP 200 was received but the server did not echo a parseable event.
        // The local state is updated optimistically. The user is informed this is unconfirmed.
        when(
          () =>
              mockLogsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => const Right(null));

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: false,
          existing: existingEvent,
          selectedStatus: 'OFF',
          startTimeStr: '08:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'Correction',
        );

        final state = container.read(editLogProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, isNotNull);
        expect(state.value!.type, EditLogOutcomeType.unconfirmed);
      },
    );

    test(
      'Right(LogEvent(syncStatus: pendingSync)) → offlineQueued (stored locally, waiting for sync)',
      () async {
        // offlineQueued means the edit is in the offline queue — it has NOT been confirmed
        // by the server. The UI shows a 'will sync' message, NOT a success message.
        final queuedEvent = existingEvent.copyWith(
          status: 'OFF',
          syncStatus: EventSyncStatus.pendingSync,
        );

        when(
          () =>
              mockLogsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => Right(queuedEvent));

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: false,
          existing: existingEvent,
          selectedStatus: 'OFF',
          startTimeStr: '08:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'Offline edit',
        );

        final state = container.read(editLogProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, isNotNull);
        expect(state.value!.type, EditLogOutcomeType.offlineQueued);
      },
    );

    test(
      'Right(LogEvent(syncStatus: none)) → confirmed (server returned the event)',
      () async {
        final confirmedEvent = existingEvent.copyWith(
          status: 'OFF',
          syncStatus: EventSyncStatus.none,
        );

        when(
          () =>
              mockLogsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => Right(confirmedEvent));

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: false,
          existing: existingEvent,
          selectedStatus: 'OFF',
          startTimeStr: '08:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'Confirmed server update',
        );

        final state = container.read(editLogProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, isNotNull);
        expect(state.value!.type, EditLogOutcomeType.confirmed);
      },
    );

    test(
      'new event: Right(LogEvent(pendingSync)) → offlineQueued (local save, not server-confirmed)',
      () async {
        final queuedEvent = LogEvent(
          id: 'new-1',
          status: 'ON',
          startTime: DateTime(2026, 1, 1, 10, 0),
          duration: const Duration(hours: 1),
          location: 'Dallas, TX',
          syncStatus: EventSyncStatus.pendingSync,
        );

        when(
          () => mockLogsNotifier.addEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => Right(queuedEvent));

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: true,
          existing: null,
          selectedStatus: 'ON',
          startTimeStr: '10:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'New offline event',
        );

        final state = container.read(editLogProvider);
        expect(state.value!.type, EditLogOutcomeType.offlineQueued);
      },
    );

    test(
      'new event: Right(LogEvent(none)) → confirmed (server returned the event)',
      () async {
        final confirmedEvent = LogEvent(
          id: 'new-2',
          status: 'ON',
          startTime: DateTime(2026, 1, 1, 10, 0),
          duration: const Duration(hours: 1),
          location: 'Dallas, TX',
          syncStatus: EventSyncStatus.none,
        );

        when(
          () => mockLogsNotifier.addEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => Right(confirmedEvent));

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: true,
          existing: null,
          selectedStatus: 'ON',
          startTimeStr: '10:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'New confirmed event',
        );

        final state = container.read(editLogProvider);
        expect(state.value!.type, EditLogOutcomeType.confirmed);
      },
    );

    test(
      'new event: Right(null) → unconfirmed (never presented as a sync confirmation)',
      () async {
        when(
          () => mockLogsNotifier.addEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => const Right(null));

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: true,
          existing: null,
          selectedStatus: 'ON',
          startTimeStr: '10:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'New unconfirmed event',
        );

        final state = container.read(editLogProvider);
        expect(state.value!.type, EditLogOutcomeType.unconfirmed);
      },
    );

    test(
      'Left(failure) → outcome is NOT set (exception is thrown, state becomes AsyncError)',
      () async {
        when(
          () =>
              mockLogsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'server.internal_error')),
        );

        final notifier = container.read(editLogProvider.notifier);
        await notifier.saveEvent(
          isNewEvent: false,
          existing: existingEvent,
          selectedStatus: 'OFF',
          startTimeStr: '08:00',
          durationStr: '01:00',
          location: 'Dallas, TX',
          reason: 'Failed update',
        );

        final state = container.read(editLogProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<EditLogError>());
        expect((state.error as EditLogError).code, EditLogErrorCode.saveFailed);
        expect(state.value, isNull);
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/duty_status_backend.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/session/auth_session_reader.dart';
import 'package:golden_feather_eld/core/utils/id_generator.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:golden_feather_eld/features/logs/data/models/log_model.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/traccar_remote_event_dispatcher.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/fake_time_authority.dart';

class _MockLocalDataSource extends Mock implements LogLocalDataSource {}
class _MockSessionReader extends Mock implements AuthSessionReader {}
class _MockDailyLogsBackend extends Mock implements DailyLogsBackend {}
class _MockDutyStatusBackend extends Mock implements DutyStatusBackend {}
class _MockDvirBackend extends Mock implements DvirBackend {}
class _MockNetworkInfo extends Mock implements NetworkInfo {}
class _FakeIdGenerator implements IdGenerator {
  @override
  String v4() => 'test-uuid-42';
}

void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(const DutyStatusId(0));
    registerFallbackValue(<String, dynamic>{});
  });

  group('Event Coordinates Pipeline: Offline Enqueue and Re-sync (Step 3)', () {
    late _MockLocalDataSource localDataSource;
    late _MockDailyLogsBackend dailyLogsBackend;
    late _MockDutyStatusBackend dutyStatusBackend;
    late _MockNetworkInfo networkInfo;
    late MemoryOfflineQueue offlineQueue;
    late LogRepositoryImpl repository;
    late FakeTimeAuthority timeAuthority;

    const testLogId = DailyLogId(501);
    const testOwnerDriverId = 101;
    const initialLat = 32.7767;
    const initialLng = -96.7970;
    const initialLocationName = 'Dallas, TX';

    final originalServerEvent = LogEvent(
      id: '9001',
      status: 'ON',
      startTime: DateTime.utc(2026, 10, 22, 8, 0, 0),
      duration: const Duration(hours: 1),
      location: initialLocationName,
      originalLatitude: initialLat,
      originalLongitude: initialLng,
    );

    setUp(() {
      localDataSource = _MockLocalDataSource();
      when(() => localDataSource.getCachedDailyForm(any())).thenAnswer((_) async => null);
      when(() => localDataSource.getCachedDailyLogs(any())).thenAnswer((_) async => null);
      dailyLogsBackend = _MockDailyLogsBackend();
      dutyStatusBackend = _MockDutyStatusBackend();
      networkInfo = _MockNetworkInfo();
      offlineQueue = MemoryOfflineQueue();
      timeAuthority = FakeTimeAuthority(initialTime: DateTime.utc(2026, 10, 22, 9, 0, 0));

      repository = LogRepositoryImpl(
        localDataSource: localDataSource,
        dailyLogsBackend: dailyLogsBackend,
        dutyStatusBackend: dutyStatusBackend,
        networkInfo: networkInfo,
        offlineQueue: offlineQueue,
        timeAuthority: timeAuthority,
        idGenerator: _FakeIdGenerator(),
      );
    });

    test(
      'editing an event offline preserves original server coordinates in PendingEvent and cache, '
      'without fabricating device GPS, and dispatches canonical network payload upon re-sync',
      () async {
        // 1. Device is offline
        when(() => networkInfo.isConnected).thenReturn(false);

        Map<String, dynamic>? upsertedCache;
        when(
          () => localDataSource.upsertCachedLogEvent(testLogId, any()),
        ).thenAnswer((invocation) async {
          upsertedCache = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        // 2. Driver edits duty status to OFF with reason, keeping original event coordinates
        final updatedEvent = originalServerEvent.copyWith(
          status: 'OFF',
        );

        final result = await repository.updateEvent(
          updatedEvent,
          reason: '30-minute break',
          logId: testLogId,
          ownerDriverId: testOwnerDriverId,
        );

        expect(result.isRight(), isTrue);
        final returnedEvent = result.getOrElse((_) => throw StateError('expected right'))!;
        expect(returnedEvent.syncStatus, EventSyncStatus.pendingSync);
        expect(returnedEvent.originalLatitude, initialLat);
        expect(returnedEvent.originalLongitude, initialLng);

        // 3. Verify local cache received original coordinates
        expect(upsertedCache, isNotNull);
        expect(upsertedCache!['originalLatitude'], initialLat);
        expect(upsertedCache!['originalLongitude'], initialLng);
        expect(upsertedCache!['location'], initialLocationName);

        // 4. Verify PendingEvent in the offline queue preserves original coordinates
        final pendingList = await offlineQueue.getPending();
        expect(pendingList.length, 1);
        final pendingEvent = pendingList.first;
        expect(pendingEvent.type, 'duty_status');
        expect(pendingEvent.payload['statusId'], 9001);
        expect(pendingEvent.payload['originalLatitude'], initialLat,
            reason: 'PendingEvent payload must carry originalLatitude without GPS fabrication');
        expect(pendingEvent.payload['originalLongitude'], initialLng,
            reason: 'PendingEvent payload must carry originalLongitude without GPS fabrication');
        expect(pendingEvent.payload['locationText'], initialLocationName);

        // 5. Re-sync phase: Device comes back online
        when(() => networkInfo.isConnected).thenReturn(true);

        RawJson? capturedPutPayload;
        when(
          () => dailyLogsBackend.updateEvent(
            logId: any(named: 'logId'),
            eventId: any(named: 'eventId'),
            event: any(named: 'event'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer((invocation) async {
          capturedPutPayload = invocation.namedArguments[#event] as RawJson;
          return ok(const <String, dynamic>{
            'event': {
              'id': 9001,
              'status': 'OFF_DUTY',
              'startTime': '2026-10-22T08:00:00Z',
            },
          });
        });

        // Instantiate dispatcher and dispatch the pending event
        final sessionReader = _MockSessionReader();
        when(() => sessionReader.getSession()).thenAnswer((_) async => null);

        final dispatcher = TraccarRemoteEventDispatcher(
          dutyStatusBackend,
          dailyLogsBackend,
          _MockDvirBackend(),
          sessionReader,
          observeAuth: () async => const DispatchAuthContext(
            driverId: testOwnerDriverId,
            transitioning: false,
          ),
        );

        final dispatchResult = await dispatcher.dispatch(pendingEvent);
        expect(dispatchResult.isRight(), isTrue);
        expect(dispatchResult.getOrElse((_) => false), isTrue);

        // 6. Verify network payload conforms to official Swagger contract:
        // PUT /eld/daily-logs/{id}/events/{eventId}
        // Location is an object with { latitude, longitude } (original coords preserved without fabricated GPS)
        // manualLocation is a string containing textual location
        expect(capturedPutPayload, isNotNull);
        expect(capturedPutPayload!['status'], 'OFF_DUTY');
        expect(capturedPutPayload!['locationText'], initialLocationName);
        expect(capturedPutPayload!['manualLocation'], initialLocationName);
        expect(capturedPutPayload!['location'], {
          'latitude': initialLat,
          'longitude': initialLng,
        });
        expect((capturedPutPayload!['location'] as Map).containsKey('description'), isFalse,
            reason: 'OAS 3.0 schema expects location: { latitude, longitude }, not description');

        // 7. Verification of local cache merge:
        // Even when server echoes back an event without coordinates, mergeJson preserves original coordinates
        const serverResponse = <String, dynamic>{
          'id': 9001,
          'status': 'OFF',
          'startTime': '2026-10-22T08:00:00Z',
          'durationSeconds': 1800,
          'location': initialLocationName,
        };
        final mergedJson = LogEventModel.mergeJson(upsertedCache!, serverResponse);
        final confirmedModel = LogEventModel.fromJson(mergedJson);
        expect(confirmedModel.originalLatitude, initialLat,
            reason: 'Original latitude survives server roundtrip without being wiped or overwritten');
        expect(confirmedModel.originalLongitude, initialLng,
            reason: 'Original longitude survives server roundtrip without being wiped or overwritten');
      },
    );

    test(
      'online updateEvent builds exact Swagger payload with resolved vehicle and coordinates',
      () async {
        when(() => networkInfo.isConnected).thenReturn(true);

        when(() => localDataSource.getCachedDailyForm(testLogId)).thenAnswer(
          (_) async => {
            'vehicle': {'id': 501, 'identifier': 'VH-501'},
          },
        );

        when(() => localDataSource.getCachedLogEvents(testLogId)).thenAnswer(
          (_) async => [
            {
              'id': 9001,
              'status': 'ON_DUTY',
              'startTime': '2026-10-22T08:00:00Z',
              'durationSeconds': 3600,
              'location': initialLocationName,
              'originalLatitude': initialLat,
              'originalLongitude': initialLng,
            },
          ],
        );

        Map<String, dynamic>? capturedPayload;
        when(
          () => dailyLogsBackend.updateEvent(
            logId: any(named: 'logId'),
            eventId: any(named: 'eventId'),
            event: any(named: 'event'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer((invocation) async {
          capturedPayload = Map<String, dynamic>.from(
            invocation.namedArguments[#event] as Map,
          );
          // Echo matching Swagger documentation:
          // { success: true, data: { event: { id, timeRange, status, specialCategory, edited, editedAt, editOrigin } } }
          return ok(<String, dynamic>{
            'event': {
              'id': 9001,
              'timeRange': {
                'startTime': '2026-10-22T08:00:00Z',
                'endTime': '2026-10-22T08:30:00Z',
                'durationSeconds': 1800,
                'durationFormatted': '30m',
              },
              'status': 'OFF_DUTY',
              'specialCategory': null,
              'edited': true,
              'editedAt': '2026-10-22T09:00:00Z',
              'editOrigin': 'DRIVER_MANUAL',
            },
          });
        });

        when(
          () => localDataSource.upsertCachedLogEvent(testLogId, any()),
        ).thenAnswer((_) async {});

        final updatedEvent = originalServerEvent.copyWith(
          status: 'OFF',
          duration: const Duration(minutes: 30),
          location: 'Amarillo, TX',
        );

        final result = await repository.updateEvent(
          updatedEvent,
          reason: 'Corrected duty status and location',
          logId: testLogId,
          ownerDriverId: testOwnerDriverId,
        );

        expect(result.isRight(), isTrue);
        final confirmed = result.getOrElse((_) => throw StateError('expected right'))!;

        // 1. Verify Swagger payload structure:
        expect(capturedPayload, isNotNull);
        expect(capturedPayload!['status'], 'OFF_DUTY');
        expect(capturedPayload!['vehicleId'], 501);
        expect(capturedPayload!['vehicle'], {'id': 501});
        expect(capturedPayload!['location'], {
          'latitude': initialLat,
          'longitude': initialLng,
          'description': 'Amarillo, TX',
          'source': 'MANUAL',
        });
        expect(capturedPayload!['manualLocation'], 'Amarillo, TX');
        expect(capturedPayload!['reason'], 'Corrected duty status and location');

        // 2. Verify confirmed event model preserved coordinates and updated location
        // despite server echo omitting location keys:
        expect(confirmed.location, 'Amarillo, TX');
        expect(confirmed.originalLatitude, initialLat);
        expect(confirmed.originalLongitude, initialLng);
        expect(confirmed.status, 'OFF');
        expect(confirmed.duration, const Duration(minutes: 30));
        expect(confirmed.syncStatus, EventSyncStatus.none);
      },
    );

    test(
      'online updateEvent without coordinates omits location object and sends manualLocation',
      () async {
        when(() => networkInfo.isConnected).thenReturn(true);
        when(() => localDataSource.getCachedDailyForm(testLogId)).thenAnswer((_) async => null);
        when(() => localDataSource.getCachedDailyLogs(testOwnerDriverId)).thenAnswer((_) async => null);
        when(() => localDataSource.getCachedLogEvents(testLogId)).thenAnswer((_) async => []);

        Map<String, dynamic>? capturedPayload;
        when(
          () => dailyLogsBackend.updateEvent(
            logId: any(named: 'logId'),
            eventId: any(named: 'eventId'),
            event: any(named: 'event'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer((invocation) async {
          capturedPayload = Map<String, dynamic>.from(
            invocation.namedArguments[#event] as Map,
          );
          return ok(<String, dynamic>{
            'event': {
              'id': 9002,
              'timeRange': {
                'startTime': '2026-10-22T10:00:00Z',
                'endTime': '2026-10-22T10:15:00Z',
                'durationSeconds': 900,
              },
              'status': 'ON_DUTY',
            },
          });
        });

        when(() => localDataSource.upsertCachedLogEvent(testLogId, any())).thenAnswer((_) async {});

        final eventWithoutCoords = LogEvent(
          id: '9002',
          status: 'ON',
          startTime: DateTime.utc(2026, 10, 22, 10, 0, 0),
          duration: const Duration(minutes: 15),
          location: 'Rest Area Mile 45',
        );

        final result = await repository.updateEvent(
          eventWithoutCoords,
          reason: 'Routine inspection',
          logId: testLogId,
          ownerDriverId: testOwnerDriverId,
        );

        expect(result.isRight(), isTrue);
        expect(capturedPayload, isNotNull);
        expect(capturedPayload!.containsKey('location'), isFalse,
            reason: 'When coordinates are absent, location object should not be sent with null/fake values');
        expect(capturedPayload!['manualLocation'], 'Rest Area Mile 45');

        final confirmed = result.getOrElse((_) => throw StateError('expected right'))!;
        expect(confirmed.location, 'Rest Area Mile 45');
        expect(confirmed.originalLatitude, isNull);
        expect(confirmed.originalLongitude, isNull);
      },
    );
  });
}

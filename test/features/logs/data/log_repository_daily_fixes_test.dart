import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/certify_dto.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/duty_status_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/utils/id_generator.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_form_update.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_events_snapshot.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_time_authority.dart';

class _Local extends Mock implements LogLocalDataSource {}

class _DailyLogs extends Mock implements DailyLogsBackend {}

class _DutyStatus extends Mock implements DutyStatusBackend {}

class _Net extends Mock implements NetworkInfo {}

class _FakeLogEvent extends Fake implements LogEvent {}

class _FakeCertifyRequest extends Fake implements CertifyRequestDto {}

class _FakeIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String v4() => 'test-uuid-${_next++}';
}

void main() {
  late _Local local;
  late _DailyLogs dailyLogs;
  late _Net net;
  late MemoryOfflineQueue queue;
  late LogRepositoryImpl repo;

  const logId = DailyLogId(42);
  final day = DateTime(2026, 9, 24);

  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(const DutyStatusId(0));
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(_FakeLogEvent());
    registerFallbackValue(_FakeCertifyRequest());
  });

  setUp(() {
    local = _Local();
    dailyLogs = _DailyLogs();
    net = _Net();
    queue = MemoryOfflineQueue();
    repo = LogRepositoryImpl(
      localDataSource: local,
      dailyLogsBackend: dailyLogs,
      dutyStatusBackend: _DutyStatus(),
      networkInfo: net,
      offlineQueue: queue,
      timeAuthority: FakeTimeAuthority(),
      idGenerator: _FakeIdGenerator(),
    );

    when(() => local.cacheLogEvents(any(), any())).thenAnswer((_) async {});
    when(() => local.cacheDailyForm(any(), any())).thenAnswer((_) async {});
    when(
      () => local.markCachedDailyLogFormComplete(
        driverId: any(named: 'driverId'),
        logId: any(named: 'logId'),
        isComplete: any(named: 'isComplete'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.markCachedDailyLogFormPendingSync(
        driverId: any(named: 'driverId'),
        logId: any(named: 'logId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.markCachedDailyLogSyncStatus(
        driverId: any(named: 'driverId'),
        logId: any(named: 'logId'),
        formStatus: any(named: 'formStatus'),
        certificationStatus: any(named: 'certificationStatus'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.getCachedLogEvents(any())).thenAnswer((_) async => null);
    when(() => local.getEvents(any())).thenAnswer((_) async => const []);
    when(() => local.updateEvent(any())).thenAnswer((_) async => true);
    when(() => local.getCachedDailyLogs(any())).thenAnswer((_) async => null);
    when(() => local.getCachedDailyForm(any())).thenAnswer((_) async => null);
  });

  group('certifyLog', () {
    test('online: confirmed only when the server says certified', () async {
      when(() => net.isConnected).thenReturn(true);
      when(() => dailyLogs.certify(any())).thenAnswer(
        (_) async => const Right(
          CertifyResponseDto(
            dailyLogId: 42,
            certificationStatus: 'CERTIFIED',
            isCertified: true,
          ),
        ),
      );

      final result = await repo.certifyLog(
        logId: logId,
        driverId: 101,
        signatureImageBase64: 'c2ln',
      );

      final submission = result.getRight().toNullable();
      expect(submission, isNotNull);
      expect(submission!.isConfirmed, isTrue);
      expect(await queue.count, 0);
      verify(
        () => local.markCachedDailyLogSyncStatus(
          driverId: 101,
          logId: logId,
          certificationStatus: 'CERTIFIED',
        ),
      ).called(1);
    });

    test(
      'online: certified=false is a retryable failure, not success',
      () async {
        when(() => net.isConnected).thenReturn(true);
        when(() => dailyLogs.certify(any())).thenAnswer(
          (_) async => const Right(
            CertifyResponseDto(
              dailyLogId: 42,
              certificationStatus: 'UNCERTIFIED',
              isCertified: false,
            ),
          ),
        );

        final result = await repo.certifyLog(
          logId: logId,
          driverId: 101,
          signatureImageBase64: 'c2ln',
        );

        final failure = result.getLeft().toNullable();
        expect(failure, isA<ServerFailure>());
        expect(failure!.message, 'certificationNotConfirmed');
        expect(await queue.count, 0);
        verifyNever(
          () => local.markCachedDailyLogSyncStatus(
            driverId: any(named: 'driverId'),
            logId: any(named: 'logId'),
            certificationStatus: any(named: 'certificationStatus'),
          ),
        );
      },
    );

    test('offline: request + signature are queued as pending sync', () async {
      when(() => net.isConnected).thenReturn(false);

      final result = await repo.certifyLog(
        logId: logId,
        driverId: 101,
        signatureImageBase64: 'c2ln',
      );

      final submission = result.getRight().toNullable();
      expect(submission, isNotNull);
      expect(submission!.isPendingSync, isTrue);

      final pending = (await queue.getReadyEvents()).single;
      expect(pending.type, 'certification');
      expect(pending.payload['logId'], logId.value);
      expect(pending.payload['signatureImage'], 'c2ln');
      expect(pending.payload['ownerDriverId'], 101);
      verify(
        () => local.markCachedDailyLogSyncStatus(
          driverId: 101,
          logId: logId,
          certificationStatus: 'PENDING_SYNC',
        ),
      ).called(1);
    });

    test('offline repeat + screen reopen keeps one request and first signature',
        () async {
      when(() => net.isConnected).thenReturn(false);

      await repo.certifyLog(
        logId: logId,
        driverId: 101,
        signatureImageBase64: 'Zmlyc3Q=',
      );
      // إعادة المحاولة عبر مستودع جديد (إعادة فتح الشاشة/التطبيق) بنفس
      // الطابور الدائم: لا طلب ثانٍ، ولا استبدال للتوقيع الأصلي.
      final reopened = LogRepositoryImpl(
        localDataSource: local,
        dailyLogsBackend: dailyLogs,
        dutyStatusBackend: _DutyStatus(),
        networkInfo: net,
        offlineQueue: queue,
        timeAuthority: FakeTimeAuthority(),
        idGenerator: _FakeIdGenerator(),
      );
      final second = await reopened.certifyLog(
        logId: logId,
        driverId: 101,
        signatureImageBase64: 'c2Vjb25k',
      );

      expect(second.getRight().toNullable()!.isPendingSync, isTrue);
      expect(await queue.count, 1);
      final pending = (await queue.getPending()).single;
      expect(pending.payload['signatureImage'], 'Zmlyc3Q=');
      expect(pending.dedupeKey, 'certification:${logId.value}:101');
    });

    test('offline concurrent taps are deduped atomically', () async {
      when(() => net.isConnected).thenReturn(false);

      final results = await Future.wait(
        List.generate(
          6,
          (i) => repo.certifyLog(
            logId: logId,
            driverId: 101,
            signatureImageBase64: 'c2lnLVRhcC0=$i',
          ),
        ),
      );

      for (final result in results) {
        expect(result.getRight().toNullable()!.isPendingSync, isTrue);
      }
      expect(await queue.count, 1);
      expect((await queue.getPending()).single.type, 'certification');
    });

    test('offline: an old queued request without dedupeKey is not duplicated',
        () async {
      when(() => net.isConnected).thenReturn(false);
      await queue.enqueue(
        PendingEvent(
          id: 'legacy-cert',
          type: 'certification',
          payload: {
            'logId': logId.value,
            'certified': true,
            'signatureImage': 'bGVnYWN5',
            'ownerDriverId': 101,
          },
          createdAt: DateTime.utc(2026, 9, 24, 8),
        ),
      );

      await repo.certifyLog(
        logId: logId,
        driverId: 101,
        signatureImageBase64: 'bmV3',
      );

      expect(await queue.count, 1, reason: 'legacy row still matches by fields');
      expect((await queue.getPending()).single.id, 'legacy-cert');
    });
  });

  group('updateEvent', () {
    LogEvent event({
      required DateTime start,
      required Duration duration,
      String location = 'Unknown Location',
    }) => LogEvent(
      id: '7',
      status: 'ON',
      startTime: start,
      duration: duration,
      location: location,
    );

    test(
      'online body uses the edited duration and drops placeholder location',
      () async {
        when(() => net.isConnected).thenReturn(true);
        Map<String, dynamic>? captured;
        when(
          () => dailyLogs.updateEvent(
            logId: any(named: 'logId'),
            eventId: any(named: 'eventId'),
            event: any(named: 'event'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer((invocation) async {
          captured = Map<String, dynamic>.from(
            invocation.namedArguments[#event] as Map,
          );
          return const Right(<String, dynamic>{
            'event': {
              'id': 7,
              'status': 'ON_DUTY',
              'startTime': '2026-09-24T22:30:00Z',
              'durationSeconds': 9000,
            },
          });
        });

        final edited = event(
          start: DateTime(2026, 9, 24, 22, 30),
          duration: const Duration(hours: 2, minutes: 30),
        );

        final result = await repo.updateEvent(
          edited,
          reason: 'Corrected start',
          logId: logId,
          ownerDriverId: 101,
        );

        expect(result.isRight(), isTrue);
        final timeRange = captured!['timeRange'] as Map<String, dynamic>;
        final start = DateTime.parse(timeRange['startTime'] as String);
        final end = DateTime.parse(timeRange['endTime'] as String);
        expect(end.difference(start), const Duration(hours: 2, minutes: 30));
        expect(end.isAfter(start), isTrue);
        expect(captured!.containsKey('location'), isFalse);
        expect(captured!.containsKey('locationText'), isFalse);
      },
    );

    test('online: zero duration sends an explicit equal endTime', () async {
      when(() => net.isConnected).thenReturn(true);
      Map<String, dynamic>? captured;
      when(
        () => dailyLogs.updateEvent(
          logId: any(named: 'logId'),
          eventId: any(named: 'eventId'),
          event: any(named: 'event'),
          expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
        ),
      ).thenAnswer((invocation) async {
        captured = Map<String, dynamic>.from(
          invocation.namedArguments[#event] as Map,
        );
        return const Right(<String, dynamic>{});
      });

      await repo.updateEvent(
        event(
          start: DateTime(2026, 9, 24, 8),
          duration: Duration.zero,
          location: 'Dock 4',
        ),
        reason: 'No time passed',
        logId: logId,
      );

      final timeRange = captured!['timeRange'] as Map<String, dynamic>;
      expect(
        DateTime.parse(timeRange['endTime'] as String),
        DateTime.parse(timeRange['startTime'] as String),
      );
      expect(
        (captured!['location'] as Map<String, dynamic>)['description'],
        'Dock 4',
      );
    });

    test('offline: queued payload keeps durationSeconds for replay', () async {
      when(() => net.isConnected).thenReturn(false);

      final result = await repo.updateEvent(
        event(
          start: DateTime(2026, 9, 24, 22, 30),
          duration: const Duration(hours: 2, minutes: 30),
        ),
        reason: 'Corrected start',
        logId: logId,
        ownerDriverId: 101,
      );

      expect(result.isRight(), isTrue);
      final pending = (await queue.getReadyEvents()).single;
      expect(pending.type, 'duty_status');
      expect(pending.payload['durationSeconds'], 9000);
      expect(pending.payload.containsKey('locationText'), isFalse);
    });
  });

  group('saveForm', () {
    const form = DailyFormUpdate(
      vehicleUniqueId: 'veh-1',
      trailers: ['T1'],
      shippingDocuments: ['D1'],
    );

    test('online failure does not cache or mark the form complete', () async {
      when(() => net.isConnected).thenReturn(true);
      when(
        () => dailyLogs.saveForm(
          logId: any(named: 'logId'),
          form: any(named: 'form'),
          expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ServerError(code: 'form.saveFailed', l10nKey: 'serverError'),
        ),
      );

      final result = await repo.saveForm(
        logId: logId,
        form: form,
        ownerDriverId: 101,
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => local.cacheDailyForm(any(), any()));
      verifyNever(
        () => local.markCachedDailyLogFormComplete(
          driverId: any(named: 'driverId'),
          logId: any(named: 'logId'),
          isComplete: any(named: 'isComplete'),
        ),
      );
      expect(await queue.count, 0);
    });

    test(
      'offline caches locally and marks pending sync, never complete',
      () async {
        when(() => net.isConnected).thenReturn(false);

        final result = await repo.saveForm(
          logId: logId,
          form: form,
          ownerDriverId: 101,
        );

        expect(result.isRight(), isTrue);
        verify(() => local.cacheDailyForm(logId, any())).called(1);
        verify(
          () => local.markCachedDailyLogFormPendingSync(
            driverId: 101,
            logId: logId,
          ),
        ).called(1);
        verifyNever(
          () => local.markCachedDailyLogFormComplete(
            driverId: any(named: 'driverId'),
            logId: any(named: 'logId'),
            isComplete: any(named: 'isComplete'),
          ),
        );
        expect((await queue.getReadyEvents()).single.type, 'daily_log_form');
      },
    );

    test('online success caches and applies the server completion', () async {
      when(() => net.isConnected).thenReturn(true);
      when(
        () => dailyLogs.saveForm(
          logId: any(named: 'logId'),
          form: any(named: 'form'),
          expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
        ),
      ).thenAnswer(
        (_) async => const Right(<String, dynamic>{
          'data': {'formStatus': 'COMPLETED'},
        }),
      );

      final result = await repo.saveForm(
        logId: logId,
        form: form,
        ownerDriverId: 101,
      );

      expect(result.isRight(), isTrue);
      verify(() => local.cacheDailyForm(logId, any())).called(1);
      verify(
        () => local.markCachedDailyLogFormComplete(
          driverId: 101,
          logId: logId,
          isComplete: true,
        ),
      ).called(1);
    });
  });

  group('getEvents', () {
    test('confirmed empty events is a server success and is cached', () async {
      when(() => net.isConnected).thenReturn(true);
      when(
        () => dailyLogs.getEvents(logId),
      ).thenAnswer((_) async => const Right({'events': <dynamic>[]}));

      final result = await repo.getEvents(logId, day);

      final snapshot = result.getRight().toNullable()!;
      expect(snapshot.source, LogEventsSource.server);
      expect(snapshot.events, isEmpty);
      final cached = verify(
        () => local.cacheLogEvents(logId, captureAny()),
      ).captured.single;
      expect(cached, isEmpty);
    });

    test('missing events key is invalid, not an empty day', () async {
      when(() => net.isConnected).thenReturn(true);
      when(
        () => dailyLogs.getEvents(logId),
      ).thenAnswer((_) async => const Right({'graphGrid': <dynamic>[]}));

      final result = await repo.getEvents(logId, day);

      expect(result.isLeft(), isTrue);
      verifyNever(() => local.cacheLogEvents(any(), any()));
    });

    test('non-list events is invalid and never overwrites the cache', () async {
      when(() => net.isConnected).thenReturn(true);
      when(
        () => dailyLogs.getEvents(logId),
      ).thenAnswer((_) async => const Right({'events': 'not-a-list'}));

      final result = await repo.getEvents(logId, day);

      expect(result.isLeft(), isTrue);
      verifyNever(() => local.cacheLogEvents(any(), any()));
    });

    test('all-corrupt events are not written over the cache', () async {
      when(() => net.isConnected).thenReturn(true);
      when(() => dailyLogs.getEvents(logId)).thenAnswer(
        (_) async => const Right({
          'events': [
            {'id': null, 'startTime': null},
          ],
        }),
      );

      final result = await repo.getEvents(logId, day);

      expect(result.isLeft(), isTrue);
      verifyNever(() => local.cacheLogEvents(any(), any()));
    });

    test('online failure falls back to a cache snapshot', () async {
      when(() => net.isConnected).thenReturn(true);
      when(() => dailyLogs.getEvents(logId)).thenAnswer(
        (_) async =>
            const Left(NetworkError(code: 'network', l10nKey: 'noInternet')),
      );
      when(() => local.getCachedLogEvents(logId)).thenAnswer(
        (_) async => [
          {
            'id': 9001,
            'status': 'DRIVING',
            'startTime': '2026-09-24T08:00:00Z',
            'durationMinutes': 60,
          },
        ],
      );

      final result = await repo.getEvents(logId, day);

      final snapshot = result.getRight().toNullable()!;
      expect(snapshot.source, LogEventsSource.cache);
      expect(snapshot.events.single.id, '9001');
      verifyNever(() => local.cacheLogEvents(any(), any()));
    });
  });
}

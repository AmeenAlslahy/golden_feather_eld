import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/duty_status_backend.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:mocktail/mocktail.dart';

class _Local extends Mock implements LogLocalDataSource {}

class _DailyLogs extends Mock implements DailyLogsBackend {}

class _DutyStatus extends Mock implements DutyStatusBackend {}

class _Net extends Mock implements NetworkInfo {}

/// SRS §6.8 Offline — the Logs list and a day's events keep working without
/// a connection from the last server snapshot; nothing is invented, nothing
/// is re-owned, and a cache failure never fails an online read.
void main() {
  late _Local local;
  late _DailyLogs dailyLogs;
  late _Net net;
  late LogRepositoryImpl repo;

  const logId = DailyLogId(42);
  final day = DateTime(2026, 9, 24);

  final serverLogs = <Map<String, dynamic>>[
    {
      'id': 42,
      'uniqueId': 'u-42',
      'logDate': '2026-09-24',
      'formattedTotalWorkTime': '3h 15m',
      'totalDurationMinutes': 195,
      'formStatus': 'COMPLETED',
      'certificationStatus': 'CERTIFIED',
      'today': true,
    },
  ];

  final serverEvents = <Map<String, dynamic>>[
    {
      'id': 9001,
      'status': 'DRIVING',
      'startTime': '2026-09-24T08:00:00Z',
      'durationMinutes': 60,
      'origin': 'AUTOMATIC',
    },
  ];

  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    local = _Local();
    dailyLogs = _DailyLogs();
    net = _Net();
    repo = LogRepositoryImpl(
      localDataSource: local,
      dailyLogsBackend: dailyLogs,
      dutyStatusBackend: _DutyStatus(),
      networkInfo: net,
    );
    when(() => local.cacheDailyLogs(any(), any())).thenAnswer((_) async {});
    when(() => local.cacheLogEvents(any(), any())).thenAnswer((_) async {});
    when(() => local.getEvents(any())).thenAnswer((_) async => const []);
  });

  group('getDailyLogs', () {
    test('online: returns server list and caches the first page', () async {
      when(() => net.isConnected).thenReturn(true);
      when(() => dailyLogs.list(
            driverId: any(named: 'driverId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => Right({'data': serverLogs}));

      final result = await repo.getDailyLogs(driverId: 106);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []).single.id, logId);
      verify(() => local.cacheDailyLogs(106, serverLogs)).called(1);
    });

    test('online: a cache write failure does not fail the read', () async {
      when(() => net.isConnected).thenReturn(true);
      when(() => local.cacheDailyLogs(any(), any()))
          .thenAnswer((_) async => throw Exception('disk full'));
      when(() => dailyLogs.list(
            driverId: any(named: 'driverId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => Right({'data': serverLogs}));

      final result = await repo.getDailyLogs(driverId: 106);
      expect(result.isRight(), isTrue);
    });

    test('offline: serves the cached snapshot for the same driver', () async {
      when(() => net.isConnected).thenReturn(false);
      when(() => local.getCachedDailyLogs(106))
          .thenAnswer((_) async => serverLogs);

      final result = await repo.getDailyLogs(driverId: 106);

      expect(result.getOrElse((_) => []).single.id, logId);
      verifyNever(() => dailyLogs.list(
            driverId: any(named: 'driverId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ));
    });

    test('offline without a snapshot: NetworkFailure (never an empty list)',
        () async {
      when(() => net.isConnected).thenReturn(false);
      when(() => local.getCachedDailyLogs(any())).thenAnswer((_) async => null);

      final result = await repo.getDailyLogs(driverId: 106);

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('getEvents', () {
    test('online: graph-grid events are returned and cached by log id',
        () async {
      when(() => net.isConnected).thenReturn(true);
      when(() => dailyLogs.getGraphGrid(logId))
          .thenAnswer((_) async => Right({'events': serverEvents}));

      final result = await repo.getEvents(logId, day);

      expect(result.getOrElse((_) => []).single.status, 'D');
      verify(() => local.cacheLogEvents(logId, serverEvents)).called(1);
    });

    test('offline: cached snapshot first, then locally recorded events',
        () async {
      when(() => net.isConnected).thenReturn(false);
      when(() => local.getCachedLogEvents(logId))
          .thenAnswer((_) async => serverEvents);
      when(() => local.getEvents(day)).thenAnswer((_) async => [
            LogEvent(
              id: 'local-1',
              status: 'ON',
              startTime: DateTime(2026, 9, 24, 10),
              duration: const Duration(minutes: 30),
              location: 'Yard',
            ),
            // Same id as a cached server event → not duplicated.
            LogEvent(
              id: '9001',
              status: 'D',
              startTime: DateTime(2026, 9, 24, 8),
              duration: const Duration(minutes: 60),
              location: '',
            ),
          ]);

      final result = await repo.getEvents(logId, day);

      final events = result.getOrElse((_) => []);
      expect(events.map((e) => e.id), ['9001', 'local-1']);
      verifyNever(() => dailyLogs.getGraphGrid(any()));
    });

    test('offline without a snapshot: only locally recorded events', () async {
      when(() => net.isConnected).thenReturn(false);
      when(() => local.getCachedLogEvents(any())).thenAnswer((_) async => null);

      final result = await repo.getEvents(logId, day);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), isEmpty);
    });
  });
}

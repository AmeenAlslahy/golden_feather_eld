import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/duty_status_backend.dart';
import 'package:golden_feather_eld/features/sync/domain/repositories/offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_form_update.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

class MockLogLocalDataSource extends Mock implements LogLocalDataSource {}
class MockDailyLogsBackend extends Mock implements DailyLogsBackend {}
class MockDutyStatusBackend extends Mock implements DutyStatusBackend {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockOfflineQueue extends Mock implements OfflineQueue {}

void main() {
  late LogRepositoryImpl repository;
  late MockLogLocalDataSource mockLocalDataSource;
  late MockDailyLogsBackend mockDailyLogsBackend;
  late MockDutyStatusBackend mockDutyStatusBackend;
  late MockNetworkInfo mockNetworkInfo;
  late MockOfflineQueue mockOfflineQueue;

  setUpAll(() {
    registerFallbackValue(PendingEvent(
      id: 'test',
      type: 'test',
      payload: const {},
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(const DailyLogId(1));
  });

  setUp(() {
    mockLocalDataSource = MockLogLocalDataSource();
    mockDailyLogsBackend = MockDailyLogsBackend();
    mockDutyStatusBackend = MockDutyStatusBackend();
    mockNetworkInfo = MockNetworkInfo();
    mockOfflineQueue = MockOfflineQueue();

    repository = LogRepositoryImpl(
      localDataSource: mockLocalDataSource,
      dailyLogsBackend: mockDailyLogsBackend,
      dutyStatusBackend: mockDutyStatusBackend,
      networkInfo: mockNetworkInfo,
      offlineQueue: mockOfflineQueue,
    );
  });

  const tLogId = DailyLogId(123);

  group('getForm', () {
    test('returns DailyFormData on successful fetch with data', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      
      final Map<String, dynamic> responseData = {
        'data': {
          'uniqueId': 'veh-1',
          'coDriverId': 42,
          'trailers': [{'trailerNumber': 'T1'}, {'trailerNumber': 'T2'}],
          'shippingDocuments': [{'documentNumber': 'D1'}]
        }
      };

      when(() => mockDailyLogsBackend.getForm(tLogId))
          .thenAnswer((_) async => Right(responseData));

      final result = await repository.getForm(tLogId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be right'),
        (form) {
          expect(form, isNotNull);
          expect(form!.vehicleUniqueId, 'veh-1');
          expect(form.coDriverId, 42);
          expect(form.trailers, const ['T1', 'T2']);
          expect(form.shippingDocuments, const ['D1']);
        },
      );
    });

    test('returns null if form is empty', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      
      final Map<String, dynamic> responseData = {'data': {}};

      when(() => mockDailyLogsBackend.getForm(tLogId))
          .thenAnswer((_) async => Right(responseData));

      final result = await repository.getForm(tLogId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be right'),
        (form) => expect(form, isNull),
      );
    });

    test('returns failure on backend error', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      
      when(() => mockDailyLogsBackend.getForm(tLogId))
          .thenAnswer((_) async => const Left(ServerError(code: 'API_ERROR')));

      final result = await repository.getForm(tLogId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (r) => fail('Should be left'),
      );
    });
  });

  group('saveForm', () {
    const tFormUpdate = DailyFormUpdate(
      vehicleUniqueId: 'veh-1',
      coDriverId: 42,
      trailers: ['T1', 'T2'],
      shippingDocuments: ['D1'],
    );

    final expectedPayload = {
      'uniqueId': 'veh-1',
      'coDriverId': 42,
      'trailers': [{'trailerNumber': 'T1'}, {'trailerNumber': 'T2'}],
      'shippingDocuments': [{'documentNumber': 'D1'}],
    };

    test('online save maps correctly to backend payload', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      
      when(() => mockDailyLogsBackend.saveForm(
        logId: tLogId,
        form: expectedPayload,
      )).thenAnswer((_) async => const Right({
        'data': {
          'formStatus': 'COMPLETED',
          'message': 'Success'
        }
      }));

      final result = await repository.saveForm(logId: tLogId, form: tFormUpdate);

      expect(result.isRight(), true);
      verify(() => mockDailyLogsBackend.saveForm(
        logId: tLogId,
        form: expectedPayload,
      )).called(1);
    });

    test('offline save enqueues identical payload to PendingEvent', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(false);
      when(() => mockOfflineQueue.enqueue(any())).thenAnswer((_) async {});

      final result = await repository.saveForm(logId: tLogId, form: tFormUpdate);

      expect(result.isRight(), true);
      
      final captured = verify(() => mockOfflineQueue.enqueue(captureAny())).captured;
      final pendingEvent = captured.first as PendingEvent;
      
      expect(pendingEvent.type, 'daily_log_form');
      
      final payload = pendingEvent.payload;
      expect(payload['logId'], tLogId.value);
      
      // Ensure the exact same payload shape is queued offline
      final formPayload = payload['form'] as Map<String, dynamic>;
      expect(formPayload, expectedPayload);
    });
  });
}

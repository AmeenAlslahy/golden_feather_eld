import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/repositories/offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';

class _Queue implements OfflineQueue {
  final List<PendingEvent> events = [];

  @override
  Future<void> enqueue(PendingEvent event) async {
    events.removeWhere((item) => item.id == event.id);
    events.add(event);
  }

  @override
  Future<List<PendingEvent>> getReadyEvents({int limit = 50}) async {
    final ready = events.where((event) => event.nextRetryAt == null).toList();
    return ready.take(limit).toList();
  }

  @override
  Future<void> updateEvent(PendingEvent event) async {
    final index = events.indexWhere((item) => item.id == event.id);
    if (index >= 0) events[index] = event;
  }

  @override
  Future<void> removeEvent(String eventId) async {
    events.removeWhere((event) => event.id == eventId);
  }

  @override
  Future<int> get count async => events.length;
}

class _Dispatcher implements RemoteEventDispatcher {
  _Dispatcher(this.result);

  final Either<Failure, bool> result;
  int calls = 0;

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    calls++;
    return result;
  }
}

class _Clock implements TimeAuthority {
  @override
  Future<void> initialize() async {}

  @override
  DateTime nowUtc() => DateTime.utc(2026, 9, 23);

  @override
  Duration get monotonicElapsed => Duration.zero;

  @override
  TrustLevel get trustLevel => TrustLevel.serverSynced;

  @override
  Future<bool> resync() async => true;
}

PendingEvent _event() {
  return PendingEvent(
    id: 'duty-1',
    type: 'duty_status',
    payload: const {
      'status': 'ON_DUTY',
      'startTime': '2026-09-23T08:15:00.000Z',
    },
    createdAt: DateTime.utc(2026, 9, 23, 8, 15),
  );
}

void main() {
  test('sync reports server acceptance and removes the stamped event', () async {
    final queue = _Queue();
    final dispatcher = _Dispatcher(const Right(true));
    final engine = SyncEngine(
      queue: queue,
      dispatcher: dispatcher,
      timeAuthority: _Clock(),
    );

    final result = await engine.submitEventAndReport(_event());

    expect(result.isRight(), isTrue);
    expect(dispatcher.calls, 1);
    expect(queue.events, isEmpty);
  });

  test('sync reports server rejection and keeps the event for retry', () async {
    final queue = _Queue();
    final dispatcher = _Dispatcher(
      const Left(ServerFailure(message: 'rejected by server')),
    );
    final engine = SyncEngine(
      queue: queue,
      dispatcher: dispatcher,
      timeAuthority: _Clock(),
    );

    final result = await engine.submitEventAndReport(_event());

    expect(result.fold((failure) => failure.message, (_) => ''), 'rejected by server');
    expect(dispatcher.calls, 1);
    expect(queue.events, isEmpty);
  });
}

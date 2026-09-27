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
    events.add(event);
  }

  @override
  Future<List<PendingEvent>> getReadyEvents({int limit = 50}) async {
    return events.take(limit).toList();
  }

  @override
  Future<void> updateEvent(PendingEvent event) async {}

  @override
  Future<void> removeEvent(String eventId) async {
    events.removeWhere((event) => event.id == eventId);
  }

  @override
  Future<int> get count async => events.length;
}

class _Dispatcher implements RemoteEventDispatcher {
  _Dispatcher(this.onDispatch);

  final Future<void> Function(PendingEvent event) onDispatch;
  final List<String> sent = [];

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    sent.add(event.id);
    await onDispatch(event);
    return const Right(true);
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

void main() {
  test('a sync requested while one is running is not dropped', () async {
    final queue = _Queue();
    late SyncEngine engine;
    final dispatcher = _Dispatcher((event) async {
      if (event.id == 'first') {
        await engine.submitEvent(PendingEvent(
          id: 'second',
          type: 'duty_status',
          payload: const {},
          createdAt: DateTime.utc(2026, 9, 23),
        ));
      }
    });
    engine = SyncEngine(
      queue: queue,
      dispatcher: dispatcher,
      timeAuthority: _Clock(),
    );

    await engine.submitEvent(PendingEvent(
      id: 'first',
      type: 'duty_status',
      payload: const {},
      createdAt: DateTime.utc(2026, 9, 23),
    ));

    expect(dispatcher.sent, ['first', 'second']);
    expect(queue.events, isEmpty);
  });
}

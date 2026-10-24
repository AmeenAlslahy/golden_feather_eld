import '../../domain/entities/pending_event.dart';
import '../../domain/entities/quarantine_record.dart';
import '../../domain/repositories/offline_queue.dart';

class MemoryOfflineQueue implements OfflineQueue {
  final List<PendingEvent> _queue = [];
  final Map<String, QuarantineRecord> _parked = {};

  @override
  Future<void> enqueue(PendingEvent event) async {
    // Deduplication check
    final existingIndex = _queue.indexWhere((e) => e.id == event.id);
    if (existingIndex >= 0) {
      _queue[existingIndex] = event; // Override if it exists (Idempotency)
    } else {
      _queue.add(event);
    }
  }

  @override
  Future<List<PendingEvent>> getReadyEvents({int limit = 50}) async {
    final now = DateTime.now();

    // فلترة الأحداث التي حان وقت محاولتها أو لم تحاول من قبل
    final readyEvents = _queue.where((e) {
      if (e.nextRetryAt == null) return true;
      return e.nextRetryAt!.isBefore(now) ||
          e.nextRetryAt!.isAtSameMomentAs(now);
    }).toList();

    // فرز حسب الأولوية ثم الأقدمية
    readyEvents.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(
          b.priority.index,
        ); // high (0), normal (1), low (2)
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return readyEvents.take(limit).toList();
  }

  @override
  Future<void> updateEvent(PendingEvent event) async {
    final index = _queue.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _queue[index] = event;
    }
  }

  @override
  Future<void> removeEvent(String eventId) async {
    _queue.removeWhere((e) => e.id == eventId);
  }

  @override
  Future<void> moveToDeadLetter(PendingEvent event) async {
    _queue.removeWhere((e) => e.id == event.id);
  }

  @override
  Future<int> get count async => _queue.length;

  void _park(
    PendingEvent event, {
    required StoredEventState state,
    required String reason,
    int? ownerDriverId,
  }) {
    _queue.removeWhere((e) => e.id == event.id);
    _parked[event.id] = QuarantineRecord(
      event: event,
      state: state,
      reason: reason,
      quarantinedAt: DateTime.now().toUtc(),
      ownerDriverId: ownerDriverId,
    );
  }

  @override
  Future<void> moveToDeferred(
    PendingEvent event, {
    required StoredEventState state,
    required String reason,
    int? ownerDriverId,
  }) async {
    assert(
      state != StoredEventState.quarantinedUnknownOwner,
      'use moveToQuarantine for unknown-owner parking',
    );
    _park(event, state: state, reason: reason, ownerDriverId: ownerDriverId);
  }

  @override
  Future<void> moveToQuarantine(
    PendingEvent event, {
    required String reason,
    int? ownerDriverId,
  }) async {
    _park(
      event,
      state: StoredEventState.quarantinedUnknownOwner,
      reason: reason,
      ownerDriverId: ownerDriverId,
    );
  }

  List<QuarantineRecord> _parkedBy(Set<StoredEventState> states, int limit) {
    final rows = _parked.values.where((r) => states.contains(r.state)).toList()
      ..sort((a, b) => a.quarantinedAt.compareTo(b.quarantinedAt));
    return rows.take(limit).toList();
  }

  @override
  Future<List<QuarantineRecord>> getDeferred({int limit = 50}) async {
    return _parkedBy(const {
      StoredEventState.deferredOwnerMismatch,
      StoredEventState.deferredUnauthenticated,
    }, limit);
  }

  @override
  Future<List<QuarantineRecord>> getQuarantined({int limit = 50}) async {
    return _parkedBy(const {StoredEventState.quarantinedUnknownOwner}, limit);
  }

  @override
  Future<void> releaseToPending(String eventId) async {
    final record = _parked.remove(eventId);
    if (record == null) return;
    await enqueue(record.event);
  }

  Future<void> clear() async {
    _queue.clear();
    _parked.clear();
  }
}

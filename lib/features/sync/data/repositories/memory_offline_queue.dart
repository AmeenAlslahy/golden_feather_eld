import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/offline_queue.dart';

class MemoryOfflineQueue implements OfflineQueue {
  final List<PendingEvent> _queue = [];

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
        return a.priority.index
            .compareTo(b.priority.index); // high (0), normal (1), low (2)
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

  Future<void> clear() async {
    _queue.clear();
  }
}

import '../../domain/entities/duty_event_record.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/duty_event_journal.dart';
import '../../domain/repositories/offline_queue.dart';

/// In-memory journal for mock/test environments. Production always uses the
/// SQLite journal on the queue database.
class MemoryDutyEventJournal implements DutyEventJournal {
  MemoryDutyEventJournal({OfflineQueue? queue}) : _queue = queue;

  final OfflineQueue? _queue;
  final List<DutyEventRecord> _records = [];

  List<DutyEventRecord> get records => List.unmodifiable(_records);

  @override
  Future<void> append(
    DutyEventRecord record, {
    PendingEvent? syncEvent,
  }) async {
    if (!_records.any((r) => r.eventId == record.eventId)) {
      _records.add(record);
    }
    if (syncEvent != null) {
      await _queue?.enqueue(syncEvent);
    }
  }

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async {
    final records = _records
        .where((r) => r.ownerDriverId == ownerDriverId)
        .toList()
      ..sort((a, b) {
        final byTime = (a.eventTimeUtc ?? a.receivedAtUtc)
            .compareTo(b.eventTimeUtc ?? b.receivedAtUtc);
        if (byTime != 0) return byTime;
        return (a.seq ?? 0).compareTo(b.seq ?? 0);
      });
    return DutyEventJournalLoad(
      records: records.take(limit).toList(),
      corruptedRows: 0,
    );
  }
}

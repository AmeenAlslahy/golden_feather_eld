import '../entities/duty_event_record.dart';
import '../entities/pending_event.dart';

/// Result of a journal read. [corruptedRows] is evidence that the journal is
/// incomplete, not permission to delete or ignore it.
class DutyEventJournalLoad {
  const DutyEventJournalLoad({
    required this.records,
    required this.corruptedRows,
  });

  final List<DutyEventRecord> records;
  final int corruptedRows;

  bool get hasCorruption => corruptedRows > 0;
}

/// Append-only duty-event evidence.
abstract interface class DutyEventJournal {
  /// Insert [record] and, when [syncEvent] is provided, its queue row in the
  /// **same transaction**. Duplicate [DutyEventRecord.eventId] is ignored so
  /// replay/retry can never create a second evidence row.
  ///
  /// Throws when the transaction fails; callers must not apply the transition
  /// in that case.
  Future<void> append(
    DutyEventRecord record, {
    PendingEvent? syncEvent,
  });

  /// Read rows for the given owner, ordered by legal time then insertion.
  /// Corrupt rows are counted and skipped, never deleted.
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  });
}

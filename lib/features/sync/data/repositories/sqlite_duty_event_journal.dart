import 'package:sqflite/sqflite.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/duty_event_record.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/duty_event_journal.dart';
import 'sqlite_offline_queue.dart';

/// P1.1 — SQLite implementation on the **same database instance** as the
/// offline queue. The journal insert and the queue insert share one
/// transaction, so a crash cannot leave one without the other.
class SqliteDutyEventJournal implements DutyEventJournal {
  SqliteDutyEventJournal(this._database);

  final Future<Database> Function() _database;

  @override
  Future<void> append(DutyEventRecord record, {PendingEvent? syncEvent}) async {
    final db = await _database();
    await db.transaction((txn) async {
      // IGNORE keeps the first evidence row for an event id. Replay/retry can
      // never rewrite or duplicate recorded evidence.
      await txn.insert(
        SQLiteOfflineQueue.journalTable,
        record.toRow(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (syncEvent != null) {
        await SQLiteOfflineQueue.insertPendingEvent(txn, syncEvent);
      }
    });
  }

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async {
    final db = await _database();
    final rows = await db.query(
      SQLiteOfflineQueue.journalTable,
      where: 'owner_driver_id = ?',
      whereArgs: [ownerDriverId],
      orderBy: 'event_time_utc ASC, seq ASC',
      limit: limit,
    );

    final records = <DutyEventRecord>[];
    var corrupted = 0;
    for (final row in rows) {
      try {
        records.add(DutyEventRecord.fromRow(row));
      } catch (e) {
        // Evidence is retained. One malformed row must not hide the rest,
        // but the caller is told the journal is incomplete.
        corrupted++;
        AppLogger.warning(
          'DutyEventJournal: corrupt row seq=${row['seq']} '
          'eventId=${row['event_id']} — retained, skipped: $e',
        );
      }
    }

    records.sort((a, b) {
      final at = a.eventTimeUtc ?? a.receivedAtUtc;
      final bt = b.eventTimeUtc ?? b.receivedAtUtc;
      final byTime = at.compareTo(bt);
      if (byTime != 0) return byTime;
      return (a.seq ?? 0).compareTo(b.seq ?? 0);
    });

    return DutyEventJournalLoad(records: records, corruptedRows: corrupted);
  }
}

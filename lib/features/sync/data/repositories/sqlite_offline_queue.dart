import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/entities/quarantine_record.dart';
import '../../domain/repositories/offline_queue.dart';

class SQLiteOfflineQueue implements OfflineQueue {
  static Database? _database;
  static const String _tableName = 'pending_events';
  static const String _quarantineTable = 'quarantine';

  /// P1.1 — append-only duty-event evidence. Lives in the same database as
  /// the queue so a journal row and its sync-queue row commit atomically.
  static const String journalTable = 'duty_event_journal';

  /// أقصى عدد صفوف في `dead_letters` (الرفض النهائي).
  ///
  /// الطلبات المرفوضة نهائياً لا تُعاد المحاولة أبداً، فيجدّ جدول
  /// الحروف الميتة بلا سقف. نحتفظ بالأحدث ونحذف الأقدم.
  static const int maxDeadLetters = 200;

  /// مسار ملف اختياري (للاختبارات بملف مؤقت). الافتراضي سلوك الإنتاج.
  final String? dbPathOverride;

  /// مصدر "الآن" الموحّد.
  ///
  /// كان `DateTime.now()` يُقارَن هنا بـ `nextRetryAt` الذي يُحسب من
  /// `TimeAuthority` في [SyncEngine]. تغيير ساعة الجهاز بين الحساب
  /// والقراءة كان يجعل الصف جاهزاً/غير جاهز في الوقت الخطأ. الافتراضي
  /// يحافظ على سلوك الاختبارات القائمة؛ الإنتاج يمرّر `nowUtc`.
  final DateTime Function()? _now;

  DateTime _currentTime() {
    final fn = _now;
    return fn != null ? fn() : DateTime.now();
  }

  SQLiteOfflineQueue({this.dbPathOverride, DateTime Function()? now})
    : _now = now;

  /// للاختبارات فقط: إغلاق الاتصال المشترك حتى يعيد مثيل جديد فتح
  /// نفس الملف (محاكاة restart) دون تسرب حالة بين الاختبارات.
  static Future<void> resetForTests() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<void> _createQuarantineTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_quarantineTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        retryCount INTEGER NOT NULL,
        ownerDriverId INTEGER,
        proof TEXT NOT NULL DEFAULT 'none',
        state TEXT NOT NULL,
        reason TEXT NOT NULL DEFAULT '',
        quarantinedAt INTEGER NOT NULL
      )
    ''');
  }

  /// P2 — فهارس تغطي استعلامات القراءة الفعلية:
  /// الطابور (`priority, createdAt`)، الحجر (`state, quarantinedAt`)،
  /// وقصّ الحروف الميتة (`failedAt`). إضافية بالكامل: `IF NOT EXISTS`
  /// تجعل الترقية قابلة للاستئناف ولا تمس أي صف.
  static Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_ready '
      'ON $_tableName(priority ASC, createdAt ASC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quarantine_state '
      'ON $_quarantineTable(state, quarantinedAt ASC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_dead_letters_failedAt '
      'ON dead_letters(failedAt DESC)',
    );
  }

  /// P0 — يمنع طلبين نشطين لنفس المفتاح المنطقي (مثل اعتماد نفس السجل
  /// لنفس السائق). فهرس جزئي: الصفوف القديمة بلا مفتاح (`NULL`) لا تتأثر.
  static Future<void> _createDedupeIndex(DatabaseExecutor db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_dedupe '
      'ON $_tableName(dedupeKey) WHERE dedupeKey IS NOT NULL',
    );
  }

  /// P1.1 — durable duty-event journal (evidence layer).
  ///
  /// `event_id` is the logical transition identity (also the queue `id` /
  /// `clientId`). `seq` is insertion order for deterministic replay when two
  /// events carry the same legal time. Rows are never deleted: sync outcome
  /// changes `sync_state` only.
  static Future<void> _createJournalTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $journalTable (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT NOT NULL UNIQUE,
        owner_driver_id INTEGER,
        source TEXT DEFAULT 'unknown',
        status TEXT NOT NULL,
        event_time_utc INTEGER,
        received_at_utc INTEGER NOT NULL,
        time_source TEXT NOT NULL,
        time_confidence TEXT NOT NULL,
        monotonic_ms INTEGER,
        payload TEXT NOT NULL,
        sync_state TEXT NOT NULL,
        server_event_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_journal_owner_time '
      'ON $journalTable(owner_driver_id, event_time_utc ASC, seq ASC)',
    );
  }

  /// Decision 3 (P0): Explicit database migration from version 6 to 7.
  /// Adds column `source` with DEFAULT 'unknown' to `duty_event_journal` if not already present,
  /// and updates existing rows with NULL or 'unknown' to 'manual'.
  /// Relies on sqflite's automatic transaction wrapping around onUpgrade (no nested transaction).
  static Future<void> _migrateToV7(DatabaseExecutor db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [journalTable],
    );
    if (tables.isEmpty) {
      await _createJournalTable(db);
    }
    final tableInfo =
        await db.rawQuery('PRAGMA table_info($journalTable)');
    final hasSourceColumn = tableInfo.any((col) => col['name'] == 'source');
    if (!hasSourceColumn) {
      await db.execute(
        "ALTER TABLE $journalTable ADD COLUMN source TEXT DEFAULT 'unknown'",
      );
    }
    await db.execute(
      "UPDATE $journalTable SET source = 'manual' WHERE source IS NULL OR source = 'unknown'",
    );
  }

  Future<Database> _initDB() async {
    final String path;
    if (dbPathOverride != null) {
      path = dbPathOverride!;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'offline_queue.db');
    }

    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            priority INTEGER NOT NULL,
            retryCount INTEGER NOT NULL,
            nextRetryAt INTEGER,
            dedupeKey TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE dead_letters (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            failedAt INTEGER NOT NULL
          )
        ''');
        await _createQuarantineTable(db);
        await _createJournalTable(db);
        await _createIndexes(db);
        await _createDedupeIndex(db);
      },
      // ترقية إضافية فقط: لا ALTER على الجداول القديمة، لا backfill،
      // لا مساس بالصفوف. IF NOT EXISTS يجعلها قابلة للاستئناف بعد crash.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE dead_letters (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              payload TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              failedAt INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await _createQuarantineTable(db);
        }
        if (oldVersion < 4) {
          await _createIndexes(db);
        }
        if (oldVersion < 5) {
          await _createJournalTable(db);
        }
        if (oldVersion < 6) {
          // عمود اختياري: الصفوف القديمة تبقى `NULL` وتُرسل كما هي.
          await db.execute('ALTER TABLE $_tableName ADD COLUMN dedupeKey TEXT');
          await _createDedupeIndex(db);
        }
        if (oldVersion < 7) {
          await _migrateToV7(db);
        }
      },
    );
  }

  /// Row shape shared by the standalone enqueue path and the atomic
  /// journal+queue transaction in [SqliteDutyEventJournal].
  static Map<String, Object?> pendingRow(PendingEvent event) => {
    'id': event.id,
    'type': event.type,
    'payload': jsonEncode(event.payload),
    'createdAt': event.createdAt.millisecondsSinceEpoch,
    'priority': event.priority.index,
    'retryCount': event.retryCount,
    'nextRetryAt': event.nextRetryAt?.millisecondsSinceEpoch,
    'dedupeKey': event.dedupeKey,
  };

  /// Insert/REPLACE a queue row inside an existing transaction or database.
  ///
  /// CONFLICT_REPLACE preserves the existing deduplication/idempotency
  /// behaviour (same `id` cannot create a second queue row).
  static Future<void> insertPendingEvent(
    DatabaseExecutor db,
    PendingEvent event,
  ) {
    return db.insert(
      _tableName,
      pendingRow(event),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> enqueue(PendingEvent event) async {
    final db = await database;
    await insertPendingEvent(db, event);
  }

  @override
  Future<bool> enqueueIfAbsent(PendingEvent event) async {
    final db = await database;
    // INSERT OR IGNORE + فهرس فريد على dedupeKey: الفحص والكتابة عملية
    // SQLite واحدة، فلا يوجد سباق بين قراءة ثم إدراج.
    final rowId = await db.insert(
      _tableName,
      pendingRow(event),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // 🔴 `rowid` الناجح يبدأ من 1 دائماً (الجدول ليس WITHOUT ROWID).
    // عند التجاهل: أندرويد يعيد -1، لكن `sqflite_common_ffi` يعيد 0.
    // فحص `!= -1` كان يعدّ 0 نجاحاً → `true` كاذبة للصف المكرر.
    return rowId > 0;
  }

  PendingEvent _toEvent(Map<String, dynamic> map) {
    return PendingEvent(
      id: map['id'] as String,
      type: map['type'] as String,
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      priority: SyncPriority.values[map['priority'] as int],
      retryCount: map['retryCount'] as int,
      nextRetryAt: map['nextRetryAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRetryAt'] as int)
          : null,
      dedupeKey: map['dedupeKey'] as String?,
    );
  }

  @override
  Future<List<PendingEvent>> getReadyEvents({int limit = 50}) async {
    final db = await database;
    final now = _currentTime().millisecondsSinceEpoch;

    // استخراج الأحداث الجاهزة (nextRetryAt <= now) أو (nextRetryAt IS NULL)
    // مرتبة بالأولوية (تصاعدياً: 0=high) ثم بالأقدمية
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'nextRetryAt IS NULL OR nextRetryAt <= ?',
      whereArgs: [now],
      orderBy: 'priority ASC, createdAt ASC',
      limit: limit,
    );

    return maps.map(_toEvent).toList();
  }

  @override
  Future<List<PendingEvent>> getPending({int limit = 1000}) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'createdAt ASC',
      limit: limit,
    );
    return maps.map(_toEvent).toList();
  }

  @override
  Future<void> updateEvent(PendingEvent event) async {
    // التحديث يعادل الإضافة بفضل CONFLICT_REPLACE
    await enqueue(event);
  }

  @override
  Future<void> removeEvent(String eventId) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [eventId]);
  }

  @override
  Future<void> moveToDeadLetter(PendingEvent event) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableName, where: 'id = ?', whereArgs: [event.id]);
      await txn.insert('dead_letters', {
        'id': event.id,
        'type': event.type,
        'payload': jsonEncode(event.payload),
        'createdAt': event.createdAt.millisecondsSinceEpoch,
        'failedAt': _currentTime().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 🧹 حصر سجلات الرفض النهائي.
      //
      // الطلبات المرفوضة نهائياً (409 على سجل معتمد مثلاً) كانت تتراكم
      // بلا حدّ: كل رفض يدخل الجدول ولا أحد يخرجه. ومع كل «رفض نهائي»
      // جديد يُمحى **الأقدم** — لا الحِدّ الأدنى للأحدث أبداً.
      //
      // ⚠️ هذا **بديل** عن أطول احتفاظ (retain-for-age) لا عن مراجعة
      // السجلّ: الصف المحذوف كان مرفوضاً نهائياً، والخادم لن يقبله
      // أبداً، ولا أثر تشغيلياً لفقده. أمّا الأحداث المعلّقة (الطابور
      // نفسه) فلا تمسّها هذه العملية إطلاقاً — لا تُفقد بيانات HOS.
      await txn.rawDelete(
        'DELETE FROM dead_letters WHERE id NOT IN ('
        '  SELECT id FROM dead_letters ORDER BY failedAt DESC LIMIT ?'
        ')',
        [maxDeadLetters],
      );
    });
  }

  @override
  Future<int> get count async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Map<String, Object?> _parkRow(
    PendingEvent event,
    StoredEventState state,
    String reason,
    int? ownerDriverId,
    OwnershipProof proof,
    int quarantinedAt,
  ) {
    return {
      'id': event.id,
      'type': event.type,
      'payload': jsonEncode(event.payload),
      'createdAt': event.createdAt.millisecondsSinceEpoch,
      'priority': event.priority.index,
      'retryCount': event.retryCount,
      'ownerDriverId': ownerDriverId,
      'proof': proof.name,
      'state': state.name,
      'reason': reason,
      'quarantinedAt': quarantinedAt,
    };
  }

  Future<void> _park(
    PendingEvent event, {
    required StoredEventState state,
    required String reason,
    int? ownerDriverId,
    OwnershipProof proof = OwnershipProof.none,
  }) async {
    final db = await database;
    // ذرية: حذف من pending + إدراج في الحجر بمعاملة واحدة —
    // crash في المنتصف يتراجع بالكامل (لا فقد ولا تكرار).
    // REPLACE يجعل النقل المتكرر idempotent (صف واحد دائماً).
    await db.transaction((txn) async {
      await txn.delete(_tableName, where: 'id = ?', whereArgs: [event.id]);
      await txn.insert(
        _quarantineTable,
        _parkRow(
          event,
          state,
          reason,
          ownerDriverId,
          proof,
          _currentTime().millisecondsSinceEpoch,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> moveToDeferred(
    PendingEvent event, {
    required StoredEventState state,
    required String reason,
    int? ownerDriverId,
  }) {
    assert(
      state != StoredEventState.quarantinedUnknownOwner,
      'use moveToQuarantine for unknown-owner parking',
    );
    return _park(
      event,
      state: state,
      reason: reason,
      ownerDriverId: ownerDriverId,
    );
  }

  @override
  Future<void> moveToQuarantine(
    PendingEvent event, {
    required String reason,
    int? ownerDriverId,
  }) {
    return _park(
      event,
      state: StoredEventState.quarantinedUnknownOwner,
      reason: reason,
      ownerDriverId: ownerDriverId,
    );
  }

  QuarantineRecord _toRecord(Map<String, Object?> map) {
    return QuarantineRecord(
      event: PendingEvent(
        id: map['id'] as String,
        type: map['type'] as String,
        payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        priority: SyncPriority.values[map['priority'] as int],
        retryCount: map['retryCount'] as int,
      ),
      state: StoredEventState.values.firstWhere(
        (s) => s.name == (map['state'] as String),
        orElse: () => StoredEventState.quarantinedUnknownOwner,
      ),
      reason: (map['reason'] as String?) ?? '',
      quarantinedAt: DateTime.fromMillisecondsSinceEpoch(
        map['quarantinedAt'] as int,
      ),
      ownerDriverId: map['ownerDriverId'] as int?,
      proof: OwnershipProof.values.firstWhere(
        (p) => p.name == (map['proof'] as String? ?? 'none'),
        orElse: () => OwnershipProof.none,
      ),
    );
  }

  Future<List<QuarantineRecord>> _parked(
    List<StoredEventState> states, {
    int limit = 50,
  }) async {
    final db = await database;
    final placeholders = states.map((_) => '?').join(', ');
    final maps = await db.query(
      _quarantineTable,
      where: 'state IN ($placeholders)',
      whereArgs: states.map((s) => s.name).toList(),
      orderBy: 'quarantinedAt ASC',
      limit: limit,
    );
    return maps.map(_toRecord).toList();
  }

  @override
  Future<List<QuarantineRecord>> getDeferred({int limit = 50}) {
    return _parked(const [
      StoredEventState.deferredOwnerMismatch,
      StoredEventState.deferredUnauthenticated,
    ], limit: limit);
  }

  @override
  Future<List<QuarantineRecord>> getQuarantined({int limit = 50}) {
    return _parked(const [
      StoredEventState.quarantinedUnknownOwner,
    ], limit: limit);
  }

  @override
  Future<void> releaseToPending(String eventId) async {
    final db = await database;
    // ذرية معكوسة: إدراج في pending + حذف من الحجر — تُستدعى من سياج
    // Part 2 فقط بعد تحقق كامل، لا تلقائياً.
    await db.transaction((txn) async {
      final rows = await txn.query(
        _quarantineTable,
        where: 'id = ?',
        whereArgs: [eventId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final record = _toRecord(rows.first);
      await txn.insert(_tableName, {
        'id': record.event.id,
        'type': record.event.type,
        'payload': jsonEncode(record.event.payload),
        'createdAt': record.event.createdAt.millisecondsSinceEpoch,
        'priority': record.event.priority.index,
        'retryCount': record.event.retryCount,
        'nextRetryAt': null,
        'dedupeKey': record.event.dedupeKey,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(_quarantineTable, where: 'id = ?', whereArgs: [eventId]);
    });
  }
}

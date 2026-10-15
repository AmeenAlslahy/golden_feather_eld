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

  /// أقصى عدد صفوف في `dead_letters` (الرفض النهائي).
  ///
  /// الطلبات المرفوضة نهائياً لا تُعاد المحاولة أبداً، فيجدّ جدول
  /// الحروف الميتة بلا سقف. نحتفظ بالأحدث ونحذف الأقدم.
  static const int maxDeadLetters = 200;

  /// مسار ملف اختياري (للاختبارات بملف مؤقت). الافتراضي سلوك الإنتاج.
  final String? dbPathOverride;

  SQLiteOfflineQueue({this.dbPathOverride});

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            priority INTEGER NOT NULL,
            retryCount INTEGER NOT NULL,
            nextRetryAt INTEGER
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
      },
    );
  }

  @override
  Future<void> enqueue(PendingEvent event) async {
    final db = await database;

    final data = {
      'id': event.id,
      'type': event.type,
      'payload': jsonEncode(event.payload),
      'createdAt': event.createdAt.millisecondsSinceEpoch,
      'priority': event.priority.index,
      'retryCount': event.retryCount,
      'nextRetryAt': event.nextRetryAt?.millisecondsSinceEpoch,
    };

    // CONFLICT_REPLACE يضمن الـ Deduplication و Idempotency
    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PendingEvent>> getReadyEvents({int limit = 50}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // استخراج الأحداث الجاهزة (nextRetryAt <= now) أو (nextRetryAt IS NULL)
    // مرتبة بالأولوية (تصاعدياً: 0=high) ثم بالأقدمية
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'nextRetryAt IS NULL OR nextRetryAt <= ?',
      whereArgs: [now],
      orderBy: 'priority ASC, createdAt ASC',
      limit: limit,
    );

    return maps.map((map) {
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
      );
    }).toList();
  }

  @override
  Future<void> updateEvent(PendingEvent event) async {
    // التحديث يعادل الإضافة بفضل CONFLICT_REPLACE
    await enqueue(event);
  }

  @override
  Future<void> removeEvent(String eventId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  @override
  Future<void> moveToDeadLetter(PendingEvent event) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [event.id],
      );
      await txn.insert(
        'dead_letters',
        {
          'id': event.id,
          'type': event.type,
          'payload': jsonEncode(event.payload),
          'createdAt': event.createdAt.millisecondsSinceEpoch,
          'failedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

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
      await txn.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [event.id],
      );
      await txn.insert(
        _quarantineTable,
        _parkRow(
          event,
          state,
          reason,
          ownerDriverId,
          proof,
          DateTime.now().millisecondsSinceEpoch,
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
    return _park(event,
        state: state, reason: reason, ownerDriverId: ownerDriverId);
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
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        priority: SyncPriority.values[map['priority'] as int],
        retryCount: map['retryCount'] as int,
      ),
      state: StoredEventState.values.firstWhere(
        (s) => s.name == (map['state'] as String),
        orElse: () => StoredEventState.quarantinedUnknownOwner,
      ),
      reason: (map['reason'] as String?) ?? '',
      quarantinedAt:
          DateTime.fromMillisecondsSinceEpoch(map['quarantinedAt'] as int),
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
    return _parked(
      const [
        StoredEventState.deferredOwnerMismatch,
        StoredEventState.deferredUnauthenticated,
      ],
      limit: limit,
    );
  }

  @override
  Future<List<QuarantineRecord>> getQuarantined({int limit = 50}) {
    return _parked(
      const [StoredEventState.quarantinedUnknownOwner],
      limit: limit,
    );
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
      await txn.insert(
        _tableName,
        {
          'id': record.event.id,
          'type': record.event.type,
          'payload': jsonEncode(record.event.payload),
          'createdAt': record.event.createdAt.millisecondsSinceEpoch,
          'priority': record.event.priority.index,
          'retryCount': record.event.retryCount,
          'nextRetryAt': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        _quarantineTable,
        where: 'id = ?',
        whereArgs: [eventId],
      );
    });
  }
}

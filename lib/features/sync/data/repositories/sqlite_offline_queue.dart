import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/offline_queue.dart';

class SQLiteOfflineQueue implements OfflineQueue {
  static Database? _database;
  static const String _tableName = 'pending_events';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_queue.db');

    return await openDatabase(
      path,
      version: 1,
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
  Future<int> get count async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

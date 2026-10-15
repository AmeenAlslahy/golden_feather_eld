/// انحدار: جدول الحروف الميتة كان ينمو بلا حدّ.
///
/// ### العطل
///
/// `RetryPolicy` تعيد المحاولة إلى ما لا نهاية (FMCSA)، فأي خطأ **عابر**
/// يبقى معلّقاً في `pending_events` — وهذا مقصود ولا يُمس.
///
/// لكن بعد إصلاح الـ409 (Task 04) صار هناك مسار ثانٍ: **الرفض النهائي**
/// يُنقل إلى `dead_letters` مباشرة بلا إعادة محاولة. ولا أحد كان يخرج
/// الصفوف منه، فينمو الجدول بلا سقف على جهاز يعمل شهوراً ببطء شبكة.
///
/// ### ما يصحّ وما لا يصحّ
///
/// - يُحذف **الأقدم** من الرفض النهائي، ويُحتفظ بالأحدث.
/// - **لا يُمس** `pending_events` إطلاقاً: بيانات HOS المعلّقة بيانات
///   قانونية لا تُفقد أبداً. هذا هو الفارق بين الحصر الآمن والفقد الصامت.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';

void main() {
  late Directory dir;
  late SQLiteOfflineQueue queue;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUpAll(() async {
    // ⚠️ `SQLiteOfflineQueue._database` **static**: أول استدعاء يفتح
    // الاتصال ويثبّته، وأي مسار لاحق يُتجاهل. فمجلد واحد.Connection واحد
    // طوال الملف — لا directories منفصلة (كانت تتنازع على نفس الجداول).
    dir = await Directory.systemTemp.createTemp('dead_letter_cap');
    queue = SQLiteOfflineQueue(dbPathOverride: '${dir.path}/q.db');
    // نُسخّح ونقرأ فوراً حتى يُثبَّت الاتصال.
    await queue.count;
  });

  setUp(() async {
    // تنظيف الصفوف بين الاختبارات — القاعدة نفسها مشتركة.
    final db = await queue.database;
    await db.delete('pending_events');
    await db.delete('dead_letters');
  });

  tearDownAll(() async {
    try {
      final db = await queue.database;
      await db.close();
    } catch (_) {
      // best-effort
    }
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on FileSystemException {
      // مقبول: يُمسح مع إغلاق العملية.
    }
  });

  PendingEvent evt(String id, {int minute = 0}) => PendingEvent(
        id: id,
        type: 'daily_log_form',
        createdAt: DateTime.utc(2026, 10, 14, 2, minute),
        payload: const {'logId': 20},
      );

  test('الرفض النهائي ينتقل من الطابور ولا يعود', () async {
    await queue.enqueue(evt('e1'));
    expect(await queue.count, 1);

    await queue.moveToDeadLetter(evt('e1'));
    expect(await queue.count, 0, reason: 'غادر الطابور نهائياً');
    expect(await queue.getReadyEvents(limit: 10), isEmpty);
  });

  test('الأحداث المعلّقة تنجو من كل عملية حصر', () async {
    for (var i = 0; i < 5; i++) {
      await queue.enqueue(evt('pending-$i', minute: i));
    }
    expect(await queue.count, 5);

    final doomed = evt('doomed', minute: 9);
    await queue.enqueue(doomed);
    await queue.moveToDeadLetter(doomed);

    // ❌ الفارق الجوهري: رصيد HOS المعلّق بيانات قانونية.
    expect(await queue.count, 5, reason: 'بيانات HOS المعلّقة سليمة');
  });

  test('الرفض النهائي المتكرر لا يترك أثراً في الطابور', () async {
    for (var i = 0; i < 3; i++) {
      final e = evt('rejected-$i', minute: i);
      await queue.enqueue(e);
      await queue.moveToDeadLetter(e);
    }
    expect(await queue.count, 0);
    expect(await queue.getReadyEvents(limit: 50), isEmpty,
        reason: 'الطلب المرفوض لا يعيد الظهور — وهذا هو إصلاح الـ409');
  });

  test('الحصر يبقى ضمن السقف ويحفظ الأحدث', () async {
    // نتجاوز السقف عمداً بأحداث مرفوضة تختلف أزمنتها.
    const overflow = 5;
    const total = SQLiteOfflineQueue.maxDeadLetters + overflow;

    for (var i = 0; i < total; i++) {
      final e = evt('rej-$i', minute: i);
      await queue.enqueue(e);
      await queue.moveToDeadLetter(e);
    }

    final db = await queue.database;
    final rows = await db.query('dead_letters');
    expect(rows.length, SQLiteOfflineQueue.maxDeadLetters,
        reason: 'الجدول لا ينمو بلا حدّ');

    final ids = rows.map((r) => r['id'] as String).toSet();
    // الأحدث بقي (آخر events دخلت).
    for (var i = total - overflow; i < total; i++) {
      expect(ids.contains('rej-$i'), isTrue, reason: 'rej-$i كان الأحدث');
    }
    // والأقدم حُذف.
    for (var i = 0; i < overflow; i++) {
      expect(ids.contains('rej-$i'), isFalse, reason: 'rej-$i الأقدم حُذف');
    }
  });

  test('الحد الأقصى ثابت ومعقول', () {
    expect(SQLiteOfflineQueue.maxDeadLetters, greaterThan(0));
    expect(SQLiteOfflineQueue.maxDeadLetters, lessThanOrEqualTo(1000),
        reason: 'سقف صغير: التشخيص لا يحتاج أرشيفاً');
  });
}

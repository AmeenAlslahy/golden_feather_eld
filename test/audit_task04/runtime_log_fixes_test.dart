/// انحدار لأعطال Runtime المُبلَّغة من سجل جهاز حقيقي.
///
/// العطلان:
///
/// 1. **تصادم صندوق Hive** — كان `HosAuditRepositoryImpl` و
///    `LogLocalDataSource` يتشاركان `audit_box` بتنسيقين مختلفين.
///    قارئ المخالفات كان يفك ترميز *قائمة* سجلات كأنها كائن مخالفة،
///    فيرمي `type 'String' is not a subtype of type 'int' of 'index'`
///    ويتعطّل سجل المخالفات القانوني بالكامل.
///
/// 2. **إعادة محاولة لا تنتهي** — رفض 409 نهائي (نموذج يوم معتمد) كان
///    يُطوى في `ServerFailure` قابل لإعادة المحاولة، و`RetryPolicy`
///    تعيد المحاولة إلى ما لا نهاية، فكان يُعاد كل ~50 ثانية للأبد.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/services/hos_audit_migration.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/hos_audit_repository_impl.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/traccar_remote_event_dispatcher.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/quarantine_record.dart';
import 'package:golden_feather_eld/features/sync/domain/repositories/offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:hive/hive.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────

/// صف مخالفة HOS — كائن JSON واحد (ما يكتبه HosAuditRepositoryImpl).
String _violationRow({
  String date = '2026-10-07',
  String type = 'dailyDrivingExceeded',
  String level = 'critical',
}) =>
    jsonEncode({
      'type': type,
      'level': level,
      'message': 'Daily driving limit exceeded',
      'timestamp': '${date}T14:30:00.000Z',
      'details': {'limit': '11h00m'},
    });

/// صف سجل يومي — **قائمة** JSON (ما يكتبه LogLocalDataSource).
///
/// هذا هو الصف الذي كان يُسقط سجل المخالفات: `jsonDecode` يُرجع List،
/// ثم `map['type']` يفهرس ListBase بمفتاح نصي.
String _logRow({String date = '2026-10-07'}) => jsonEncode([
      {
        'id': 'evt-1',
        'timestamp': '${date}T09:15:00.000Z',
        'driverId': '2',
        'oldStatus': 'offDuty',
        'newStatus': 'onDuty',
        'action': 'update',
        'entityType': 'daily_log',
        'entityId': '20',
      },
      {
        'id': 'evt-2',
        'timestamp': '${date}T10:00:00.000Z',
        'driverId': '2',
        'oldStatus': 'onDuty',
        'newStatus': 'driving',
        'action': 'update',
        'entityType': 'daily_log',
        'entityId': '20',
      },
    ]);

HosViolation _violation() => HosViolation(
      type: HosViolationType.dailyDrivingExceeded,
      level: ViolationLevel.critical,
      message: 'Daily driving limit exceeded',
      timestamp: DateTime.utc(2026, 10, 7, 14, 30),
      details: const {'limit': '11h00m'},
    );

// ─── Part 1: تصادم الصندوق + الترحيل ─────────────────────────────────────

void main() {
  late Directory tempDir;
  int boxSeq = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hos_audit_regression');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  String nextBox() => 'box_${boxSeq++}';

  group('العطل 1 — تصادم صندوق Hive بين المخالفات وسجلات السجلات', () {
    test('القارئ يقرأ المخالفات عندما يكون الصندوق نظيفاً', () async {
      final box = await Hive.openBox<String>(nextBox());
      await box.put('2026-10-07_dailyDrivingExceeded', _violationRow());

      final result = await HosAuditRepositoryImpl(box).getViolations();

      expect(result, hasLength(1));
      expect(result.first.type, HosViolationType.dailyDrivingExceeded);
      expect(result.first.level, ViolationLevel.critical);
      expect(result.first.details, {'limit': '11h00m'});
    });

    test('العطل المُبلَّغ: صفوف السجلات لا تُسقط قراءة المخالفات',
        () async {
      final box = await Hive.openBox<String>(nextBox());
      // نفس الصفوف التي ظهرت في سجل الجهاز: مفاتيح تواريخ + قوائم JSON.
      for (final d in ['2026-10-02', '2026-10-03', '2026-10-07', '2026-10-12']) {
        await box.put(d, _logRow(date: d));
      }
      await box.put('2026-10-07_dailyDrivingExceeded', _violationRow());

      // قبل الإصلاح كان هذا يفرض
      // "type 'String' is not a subtype of type 'int' of 'index'".
      final result = await HosAuditRepositoryImpl(box).getViolations();

      expect(result, hasLength(1));
      expect(result.first.type, HosViolationType.dailyDrivingExceeded);
    });

    test('صفوف غريبة (قائمة، نص، null، تالف) لا تُسقط السجل', () async {
      final box = await Hive.openBox<String>(nextBox());
      await box.put('2026-10-07', _logRow()); // قائمة
      await box.put('2026-10-08', 'not json at all'); // تالف
      await box.put('2026-10-09', jsonEncode(['a'])); // قائمة نصية
      await box.put('2026-10-10', jsonEncode({'type': 'x'})); // ناقص
      await box.put('2026-10-11', ''); // فارغ
      await box.put(
          '2026-10-13_dailyDrivingExceeded',
          jsonEncode({
            'type': 'noSuchType',
            'level': 'critical',
            'timestamp': '2026-10-13T00:00:00Z',
          })); // تعداد مجهول
      await box.put(
          '2026-10-14_dailyDrivingExceeded',
          jsonEncode({
            'type': 'dailyDrivingExceeded',
            'level': 'critical',
            'timestamp': 'not-a-date',
          })); // تاريخ غير قابل للتحليل
      await box.put('2026-10-15_no30MinBreakAfter8h', _violationRow(
        type: 'no30MinBreakAfter8h',
        level: 'medium',
      ));

      final result = await HosAuditRepositoryImpl(box).getViolations();

      // الصف الصحيح الوحيد هو ما يُقرأ.
      expect(result, hasLength(1));
      expect(result.first.type, HosViolationType.no30MinBreakAfter8h);
    });

    test('منع التكرار يعمل: نفس النوع ونفس اليوم لا يُكتب مرتين', () async {
      final box = await Hive.openBox<String>(nextBox());
      final repo = HosAuditRepositoryImpl(box);

      await repo.logViolation(_violation());
      await repo.logViolation(_violation());

      expect(box.length, 1);
      expect((await repo.getViolations()), hasLength(1));
    });

    test('يوم مختلف ⇒ مخالفة منفصلة', () async {
      final box = await Hive.openBox<String>(nextBox());
      final repo = HosAuditRepositoryImpl(box);

      await repo.logViolation(_violation());
      await repo.logViolation(HosViolation(
        type: HosViolationType.dailyDrivingExceeded,
        level: ViolationLevel.critical,
        message: 'x',
        timestamp: DateTime.utc(2026, 10, 8, 14, 30),
      ));

      expect(box.length, 2);
      expect(await repo.getViolations(), hasLength(2));
    });
  });

  group('الترحيل — نقل المخالفات دون لمس سجلات السجلات', () {
    test('ينقل المخالفات فقط ويترك صفوف السجلات في صندوقها', () async {
      final legacy = await Hive.openBox<String>(nextBox());
      final target = await Hive.openBox<String>(nextBox());

      await legacy.put('2026-10-02', _logRow(date: '2026-10-02'));
      await legacy.put('2026-10-07', _logRow(date: '2026-10-07'));
      await legacy.put('2026-10-07_dailyDrivingExceeded', _violationRow());
      await legacy.put('2026-10-08_shift8Hour', _violationRow(
            date: '2026-10-08',
            type: 'dailyWorkExceeded',
            level: 'medium',
          ));

      final report = await HosAuditBoxMigration(
        legacyBox: legacy,
        targetBox: target,
      ).run();

      expect(report.migrated, 2);
      expect(report.skippedLogRows, 2);
      expect(report.malformed, 0);

      // صفوف السجلات لم تُمَس.
      expect(legacy.containsKey('2026-10-02'), isTrue);
      expect(legacy.containsKey('2026-10-07'), isTrue);
      // المخالفات انتقلت.
      expect(legacy.containsKey('2026-10-07_dailyDrivingExceeded'), isFalse);
      expect(legacy.containsKey('2026-10-08_dailyWorkExceeded'), isFalse);
      expect(target.containsKey('2026-10-07_dailyDrivingExceeded'), isTrue);

      // والمخالفات تُقرأ فعلياً من الصندوق الجديد.
      final result = await HosAuditRepositoryImpl(target).getViolations();
      expect(result, hasLength(2));
      expect(result.map((v) => v.type),
          containsAll([HosViolationType.dailyDrivingExceeded,
              HosViolationType.dailyWorkExceeded]));
    });

    test('الترحيل آمن التكرار (idempotent)', () async {
      final legacy = await Hive.openBox<String>(nextBox());
      final target = await Hive.openBox<String>(nextBox());
      await legacy.put('2026-10-07', _logRow());
      await legacy.put('2026-10-07_dailyDrivingExceeded', _violationRow());

      await HosAuditBoxMigration(legacyBox: legacy, targetBox: target).run();
      // تشغيل ثانٍ علىLegacy نظيف — يجب ألا يفعل شيئاً.
      final second = await HosAuditBoxMigration(
        legacyBox: legacy,
        targetBox: target,
      ).run();

      expect(second.migrated, 0);
      expect(second.skippedLogRows, 1); // صف السجل ما زال مكانه
      expect(target.length, 1);
    });

    test('dryRun يفحص ولا يكتب', () async {
      final legacy = await Hive.openBox<String>(nextBox());
      final target = await Hive.openBox<String>(nextBox());
      await legacy.put('2026-10-07_dailyDrivingExceeded', _violationRow());

      final report = await HosAuditBoxMigration(
        legacyBox: legacy,
        targetBox: target,
        dryRun: true,
      ).run();

      expect(report.migrated, 1);
      expect(target.isEmpty, isTrue);
      expect(legacy.containsKey('2026-10-07_dailyDrivingExceeded'), isTrue);
    });

    test('تمييز الصفوف لا يعتمد على arbitrariness — كائن بالمفاتيح الثلاثة',
        () {
      // مخالفة: مفتاح فيه "_" + كائن بالمفاتيح الثلاثة.
      expect(HosAuditBoxMigration.isHosViolationRow(
        '2026-10-07_dailyDrivingExceeded',
        _violationRow(),
      ), isTrue);
      // سجل يومي: مفتاح تاريخ بلا "_" + قائمة.
      expect(HosAuditBoxMigration.isHosViolationRow('2026-10-07', _logRow()),
          isFalse);
      // حتى لو أُعطي مفتاحاً بالشكل الصحيح، القيمة قائمة ⇒ لا مخالفة.
      expect(
          HosAuditBoxMigration.isHosViolationRow(
              '2026-10-07_dailyDrivingExceeded', _logRow()),
          isFalse);
      // JSON تالف.
      expect(HosAuditBoxMigration.isHosViolationRow(
          '2026-10-07_x', '{{{'),
          isFalse);
    });
  });

  // ─── Part 2: الرفض النهائي 409 ─────────────────────────────────────────

  group('العطل 2 — رفض 409 نهائي لا يُعاد إلى الأبد', () {
    test('تصنيف الأخطاء: النهائي مقابل العابر', () {
      // ✅ نهائي — الخادم لن يقبلها مهما أعدنا الإرسال.
      expect(
        isTerminalDispatchRejection(const ConflictError(
          code: 'BUSINESS_RULE_VIOLATION',
          l10nKey: 'logAlreadyCertified',
        )),
        isTrue,
      );
      expect(
        isTerminalDispatchRejection(const ValidationError(
          code: 'invalid_payload',
          l10nKey: 'validationError',
        )),
        isTrue,
      );
      expect(isTerminalDispatchRejection(const NotFoundError()), isTrue);
      expect(isTerminalDispatchRejection(const PermissionError()), isTrue);

      // ❌ عابر — حماية FMCSA كاملة (لا تُفقد بيانات HOS).
      expect(
        isTerminalDispatchRejection(const NetworkError(
          code: 'network.timeout',
          l10nKey: 'timeout',
        )),
        isFalse,
      );
      expect(
        isTerminalDispatchRejection(const ServerError(
          code: 'server.500',
          statusCode: 500,
        )),
        isFalse,
      );
      expect(isTerminalDispatchRejection(const SessionExpiredError()), isFalse);
      expect(
        isTerminalDispatchRejection(const SyncError(
          code: 'sync.overflow',
          l10nKey: 'syncError',
        )),
        isFalse,
      );
    });

    test('المحرك ينقل المرفوض نهائياً إلى dead-letter بلا إعادة محاولة',
        () async {
      final queue = _RecordingQueue();
      final dispatcher = _ConstantDispatcher(
        const Left(RejectedFailure(code: 'BUSINESS_RULE_VIOLATION')),
      );
      final engine = SyncEngine(
        queue: queue,
        dispatcher: dispatcher,
        timeAuthority: _Clock(),
      );
      await queue.enqueue(_event('evt-409'));

      // ثلاث دورات مزامنة متتالية — يجب ألا يُعاد الإرسال بعد الأولى.
      await engine.triggerSync();
      await engine.triggerSync();
      await engine.triggerSync();

      expect(dispatcher.dispatched, hasLength(1), reason: 'إرسال واحد فقط');
      expect(dispatcher.dispatched, ['evt-409']);
      expect(queue.deadLettered, hasLength(1));
      expect(queue.deadLettered.single.id, 'evt-409');
      // وبلا تأجيل مفتوح.
      expect(await queue.count, 0);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('الأخطاء العابرة تحتفظ بإعادة المحاولة (FMCSA)', () async {
      final clock = _Clock();
      final queue = _RecordingQueue(now: clock.nowUtc);
      final dispatcher = _ConstantDispatcher(
        const Left(ServerFailure(message: 'server.500')),
      );
      final engine = SyncEngine(
        queue: queue,
        dispatcher: dispatcher,
        timeAuthority: clock,
      );
      await queue.enqueue(_event('evt-transient'));

      await engine.triggerSync();
      expect(dispatcher.dispatched, hasLength(1));
      // لم يُحذف ولا دُفن — backoff فقط.
      expect(queue.deadLettered, isEmpty);
      expect(queue.removed, isEmpty);
      expect(await queue.count, 1);

      // بعد انقضاء نافذة backoff يُعاد المحاولة — لا تُفقد بيانات HOS.
      clock.advance(const Duration(seconds: 60));
      await engine.triggerSync();
      expect(dispatcher.dispatched, hasLength(2));
      expect(queue.deadLettered, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('المحرك لا يعلّق عند رفض نهائي مع حقول payload ناقصة', () async {
      final queue = _RecordingQueue();
      final dispatcher = _ConstantDispatcher(
        const Left(ServerFailure(message: 'daily log id is missing')),
      );
      final engine = SyncEngine(
        queue: queue,
        dispatcher: dispatcher,
        timeAuthority: _Clock(),
      );
      await queue.enqueue(_event('evt-no-id'));

      await engine.triggerSync().timeout(const Duration(seconds: 10));
      expect(dispatcher.dispatched, hasLength(1));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

// ─── Harness ──────────────────────────────────────────────────────────────

PendingEvent _event(String id) => PendingEvent(
      id: id,
      type: 'daily_log_form',
      createdAt: DateTime.utc(2026, 10, 7, 12),
      payload: const {'logId': 20, 'form': <String, dynamic>{}},
    );

class _ConstantDispatcher implements RemoteEventDispatcher {
  _ConstantDispatcher(this.result);

  final Either<Failure, bool> result;

  /// كل إرسال فعلي تم — المؤشر الحقيقي لعدد محاولات الشبكة.
  final List<String> dispatched = [];

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    dispatched.add(event.id);
    return result;
  }
}

class _RecordingQueue implements OfflineQueue {
  final List<PendingEvent> events = [];
  final List<PendingEvent> deadLettered = [];
  final List<String> removed = [];
  int dispatchCount = 0;

  /// ي honoured نافذة backoff، وإلا عاد الحدث فوراً و adeار to الأبد.
  final DateTime Function() now;

  _RecordingQueue({DateTime Function()? now})
      : now = now ?? (() => DateTime.utc(2026, 10, 7, 12));

  @override
  Future<void> enqueue(PendingEvent event) async => events.add(event);

  @override
  Future<List<PendingEvent>> getReadyEvents({int limit = 50}) async {
    dispatchCount++;
    final ready = events
        .where((e) => e.nextRetryAt == null || !e.nextRetryAt!.isAfter(now()))
        .take(limit)
        .toList();
    for (final e in ready) {
      events.remove(e);
    }
    return ready;
  }

  @override
  Future<void> updateEvent(PendingEvent event) async {
    events.removeWhere((e) => e.id == event.id);
    events.add(event);
  }

  @override
  Future<void> moveToDeadLetter(PendingEvent event) async =>
      deadLettered.add(event);

  @override
  Future<void> moveToDeferred(
    PendingEvent event, {
    required StoredEventState state,
    required String reason,
    int? ownerDriverId,
  }) async {}

  @override
  Future<void> moveToQuarantine(
    PendingEvent event, {
    required String reason,
    int? ownerDriverId,
  }) async {}

  @override
  Future<List<QuarantineRecord>> getDeferred({int limit = 50}) async => [];

  @override
  Future<List<QuarantineRecord>> getQuarantined({int limit = 50}) async => [];

  @override
  Future<void> releaseToPending(String eventId) async {}

  @override
  Future<void> removeEvent(String eventId) async => removed.add(eventId);

  @override
  Future<int> get count async => events.length;
}

class _Clock implements TimeAuthority {
  DateTime _now = DateTime.utc(2026, 10, 7, 12);

  void advance(Duration d) => _now = _now.add(d);

  @override
  DateTime nowUtc() => _now;

  @override
  Duration get monotonicElapsed => Duration.zero;

  @override
  TrustLevel get trustLevel => TrustLevel.ntpSynced;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> resync() async => false;
}
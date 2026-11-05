import '../../../../core/events/app_events.dart';
import '../../../../core/utils/logger.dart';
import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/entities/sync_verification.dart';
import '../../../sync/domain/repositories/offline_queue.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/saved_form_status.dart';
import '../datasources/log_local_data_source.dart';
import '../models/log_model.dart';
import '../models/saved_form_dto.dart';

/// يترجم نتيجة مزامنة الاعتماد/النموذج إلى حالة مخزّنة + إشارة واجهة.
///
/// - `confirmed` للاعتماد لا يُقبل إلا إذا أكد الخادم `isCertified`.
/// - نجاح حفظ النموذج يحدّث الحالة من استجابة الخادم فقط؛ غياب تأكيد
///   الاكتمال يصبح `SAVED_UNCONFIRMED` لا `COMPLETED`.
/// - الرفض النهائي/استنفاد المحاولات يصبح `SYNC_FAILED` مستقلاً عن
///   `PENDING_SYNC` وعن المحفوظ، مع إبقاء بيانات المستخدم في الكاش.
class LogSyncOutcomeHandler {
  final LogLocalDataSource _local;
  final AppEventBus _events;

  /// اختياري: لفحص تعديلات أخرى معلّقة لنفس الحدث. عند تعديل حدث أكثر
  /// من مرة دون اتصال، تأكيد الأقدم لا يجوز أن يمسح شارة «بانتظار
  /// المزامنة» بينما الأحدث ما زال في الطابور.
  final OfflineQueue? _queue;

  const LogSyncOutcomeHandler({
    required LogLocalDataSource local,
    required AppEventBus events,
    OfflineQueue? queue,
  }) : _local = local,
       _events = events,
       _queue = queue;

  Future<void> onVerified(VerifiedSyncResult result) async {
    final logId = _logIdOf(result.event);
    if (logId == null) return;

    switch (result.event.type) {
      case 'certification':
        await _applyCertification(
          logId: logId,
          ownerDriverId: result.ownerDriverId,
          verification: result.verification,
        );
      case 'daily_log_form':
        await _applyForm(
          event: result.event,
          logId: logId,
          ownerDriverId: result.ownerDriverId,
          verification: result.verification,
          serverData: result.serverData,
        );
      case 'duty_status':
        await _applyDutyStatus(
          event: result.event,
          logId: logId,
          verification: result.verification,
          serverData: result.serverData,
        );
    }
  }

  /// يُستدعى عندما يخرج الحدث من الطابور نهائياً (رفض خادم أو استنفاد
  /// محاولات). لا يُستدعى عند النجاح المؤكد.
  Future<void> onDeadLettered(PendingEvent event) async {
    final logId = _logIdOf(event);
    if (logId == null) return;

    if (event.type == 'duty_status') {
      final eventId = _editedEventIdOf(event);
      if (eventId == null) return;
      final hasNewer = await _hasOtherPendingEdit(event, logId, eventId);
      await _local.setCachedEventSyncStatus(
        logId: DailyLogId(logId),
        eventId: eventId,
        status: hasNewer
            ? EventSyncStatus.pendingSync
            : EventSyncStatus.syncFailed,
      );
      _events.fire(AppEvent.logDataChanged);
      return;
    }

    final owner = _ownerOf(event) ?? await _local.ownerOfCachedLog(logId);
    if (owner == null || owner <= 0) return;

    switch (event.type) {
      case 'certification':
        await _local.markCachedDailyLogSyncStatus(
          driverId: owner,
          logId: DailyLogId(logId),
          certificationStatus: 'SYNC_FAILED',
        );
        _events.fire(AppEvent.logDataChanged);
      case 'daily_log_form':
        final form = event.payload['form'];
        if (form is Map) {
          await _local.cacheDailyForm(
            DailyLogId(logId),
            Map<String, dynamic>.from(form),
          );
        }
        await _local.markCachedDailyLogSyncStatus(
          driverId: owner,
          logId: DailyLogId(logId),
          formStatus: 'SYNC_FAILED',
        );
        _events.fire(AppEvent.logDataChanged);
    }
  }

  /// نتيجة مزامنة تعديل حدث: المؤكد يمسح العلامة (ويثري الكاش بردّ
  /// الخادم إن وُجد)، والرفض النهائي يعلّم `SYNC_FAILED`، والعابر يبقي
  /// `PENDING_SYNC` بلا إعادة بناء للواجهة.
  Future<void> _applyDutyStatus({
    required PendingEvent event,
    required int logId,
    required SyncVerification verification,
    required Map<String, dynamic>? serverData,
  }) async {
    final eventId = _editedEventIdOf(event);
    if (eventId == null) return;
    final target = DailyLogId(logId);

    switch (verification) {
      case SyncVerification.retryable:
        await _local.setCachedEventSyncStatus(
          logId: target,
          eventId: eventId,
          status: EventSyncStatus.pendingSync,
        );
      case SyncVerification.rejected:
        await _local.setCachedEventSyncStatus(
          logId: target,
          eventId: eventId,
          status: EventSyncStatus.syncFailed,
        );
        _events.fire(AppEvent.logDataChanged);
      case SyncVerification.confirmed:
        // تعديل لاحق لنفس الحدث ما زال في الطابور: لا ندّعي الاكتمال.
        if (await _hasOtherPendingEdit(event, logId, eventId)) {
          await _local.setCachedEventSyncStatus(
            logId: target,
            eventId: eventId,
            status: EventSyncStatus.pendingSync,
          );
          return;
        }
        await _mergeConfirmedEvent(
          logId: target,
          eventId: eventId,
          serverData: serverData,
        );
        await _local.setCachedEventSyncStatus(
          logId: target,
          eventId: eventId,
          status: EventSyncStatus.none,
        );
        _events.fire(AppEvent.logDataChanged);
    }
  }

  /// يدمج حدث الخادم المؤكد مع النسخة المخزّنة كي لا يمحو ردٌّ ناقص
  /// الحقول (مثل `location`) تعديل المستخدم. الرد غير القابل للتفسير
  /// لا يُفشل الطلب؛ مسح العلامة وحده يكفي.
  Future<void> _mergeConfirmedEvent({
    required DailyLogId logId,
    required String eventId,
    required Map<String, dynamic>? serverData,
  }) async {
    if (serverData == null || serverData.isEmpty) return;
    final rawEvent = serverData['event'];
    final incoming = rawEvent is Map
        ? Map<String, dynamic>.from(rawEvent)
        : serverData['id'] != null &&
              (serverData['timeRange'] != null ||
                  serverData['startTime'] != null ||
                  serverData['time'] != null)
        ? Map<String, dynamic>.from(serverData)
        : null;
    if (incoming == null || incoming['id']?.toString() != eventId) return;

    try {
      final cached = await _local.getCachedLogEvents(logId) ?? const [];
      Map<String, dynamic>? existing;
      for (final row in cached) {
        if (row['id']?.toString() == eventId) {
          existing = row;
          break;
        }
      }
      final merged = LogEventModel.mergeJson(existing ?? const {}, incoming);
      merged.remove('syncStatus');
      await _local.upsertCachedLogEvent(logId, merged);
    } catch (e) {
      AppLogger.warning('mergeConfirmedEvent skipped: $e');
    }
  }

  /// هل يوجد تعديل آخر معلّق لنفس الحدث غير الحدث الجاري؟
  Future<bool> _hasOtherPendingEdit(
    PendingEvent event,
    int logId,
    String eventId,
  ) async {
    final queue = _queue;
    if (queue == null) return false;
    try {
      final pending = await queue.getPending(limit: 1000);
      return pending.any((other) {
        if (other.id == event.id || other.type != 'duty_status') return false;
        if (_logIdOf(other) != logId) return false;
        return _editedEventIdOf(other) == eventId;
      });
    } catch (e) {
      AppLogger.warning('hasOtherPendingEdit failed: $e');
      return false;
    }
  }

  Future<void> _applyCertification({
    required int logId,
    required int ownerDriverId,
    required SyncVerification verification,
  }) async {
    final status = switch (verification) {
      SyncVerification.confirmed => 'CERTIFIED',
      SyncVerification.rejected => 'SYNC_FAILED',
      SyncVerification.retryable => 'PENDING_SYNC',
    };
    await _local.markCachedDailyLogSyncStatus(
      driverId: ownerDriverId,
      logId: DailyLogId(logId),
      certificationStatus: status,
    );
    // لا نطلق تحديث واجهة لكل فشل عابر (الطلب ما زال pending)؛ التغيير
    // المرئي يحدث عند التأكيد أو الرفض النهائي فقط.
    if (verification != SyncVerification.retryable) {
      _events.fire(AppEvent.logDataChanged);
    }
  }

  Future<void> _applyForm({
    required PendingEvent event,
    required int logId,
    required int ownerDriverId,
    required SyncVerification verification,
    required Map<String, dynamic>? serverData,
  }) async {
    final form = event.payload['form'];
    if (form is Map) {
      // بيانات المستخدم تبقى محفوظة حتى عند الرفض النهائي — لا حذف.
      await _local.cacheDailyForm(
        DailyLogId(logId),
        Map<String, dynamic>.from(form),
      );
    }

    final status = switch (verification) {
      SyncVerification.rejected => 'SYNC_FAILED',
      SyncVerification.retryable => 'PENDING_SYNC',
      SyncVerification.confirmed => _confirmedFormStatus(
        serverData == null ? null : SavedFormDto.fromJson(serverData),
      ),
    };

    await _local.markCachedDailyLogSyncStatus(
      driverId: ownerDriverId,
      logId: DailyLogId(logId),
      formStatus: status,
    );
    if (verification != SyncVerification.retryable) {
      _events.fire(AppEvent.logDataChanged);
    }
  }

  /// حالة wire من استجابة الخادم. غياب تأكيد الاكتمال ليس اكتمالاً.
  static String _confirmedFormStatus(SavedFormRead? read) {
    if (read?.complete == true) return 'COMPLETED';
    if (read?.complete == false) return 'INCOMPLETE';
    return 'SAVED_UNCONFIRMED';
  }

  /// معرّف الحدث المعدّل: `clientId` (حدث موجود) ثم `statusId` كاحتياط
  /// للعناصر القديمة في الطابور.
  static String? _editedEventIdOf(PendingEvent event) {
    if (event.type != 'duty_status') return null;
    final raw = event.payload['clientId'] ?? event.payload['statusId'];
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static int? _logIdOf(PendingEvent event) {
    if (event.type != 'certification' &&
        event.type != 'daily_log_form' &&
        event.type != 'duty_status') {
      return null;
    }
    final raw = event.payload['logId'];
    final value = raw is int ? raw : int.tryParse('${raw ?? ''}');
    return value != null && value > 0 ? value : null;
  }

  static int? _ownerOf(PendingEvent event) {
    final raw = event.payload['ownerDriverId'];
    final value = raw is int ? raw : int.tryParse('${raw ?? ''}');
    return value != null && value > 0 ? value : null;
  }
}

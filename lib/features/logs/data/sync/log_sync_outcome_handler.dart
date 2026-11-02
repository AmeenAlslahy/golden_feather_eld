import '../../../../core/events/app_events.dart';
import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/entities/sync_verification.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/saved_form_status.dart';
import '../datasources/log_local_data_source.dart';
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

  const LogSyncOutcomeHandler({
    required LogLocalDataSource local,
    required AppEventBus events,
  }) : _local = local,
       _events = events;

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
    }
  }

  /// يُستدعى عندما يخرج الحدث من الطابور نهائياً (رفض خادم أو استنفاد
  /// محاولات). لا يُستدعى عند النجاح المؤكد.
  Future<void> onDeadLettered(PendingEvent event) async {
    final logId = _logIdOf(event);
    if (logId == null) return;
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
        await _local.markCachedDailyLogSyncStatus(
          driverId: owner,
          logId: DailyLogId(logId),
          formStatus: 'SYNC_FAILED',
        );
        _events.fire(AppEvent.logDataChanged);
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

  static int? _logIdOf(PendingEvent event) {
    if (event.type != 'certification' && event.type != 'daily_log_form') {
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

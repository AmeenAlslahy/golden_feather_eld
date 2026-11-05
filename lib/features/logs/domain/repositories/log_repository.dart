import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/daily_log.dart';
import '../entities/daily_log_page.dart';
import '../../../../domain/shared/value_objects.dart';
import '../entities/audit_entry.dart';
import '../saved_form_status.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../entities/log_readiness.dart';
import '../entities/log_certify_state.dart';
import '../entities/daily_form_data.dart';
import '../entities/daily_form_update.dart';
import '../entities/certify_submission.dart';
import '../entities/log_events_snapshot.dart';

abstract class LogRepository {
  /// قائمة السجلات اليومية (`GET /eld/daily-logs` الموحّد): ترقيم
  /// `page`/`size` + `pagination` من الخادم (لا offset يدوي بعد الآن).
  Future<Either<Failure, DailyLogPage>> getDailyLogs({
    required int driverId,
    int page = 0,
    int size = 20,
  });

  /// تفاصيل سجل واحد من الخادم (`GET /eld/daily-logs/{id}`) — مصدر الحقيقة
  /// لشاشة التفاصيل (السائق/المركبة/الناقل/العناوين/الشاحنات). قراءة شبكية
  /// فقط: القائمة المخزّنة محلياً تغطي وضع عدم الاتصال.
  Future<Either<Failure, DailyLog>> getLogById(DailyLogId logId);

  /// Reads the saved daily log form snapshot from the backend.
  /// Returns null if the form is empty or doesn't exist on the server.
  Future<Either<Failure, DailyFormData?>> getForm(DailyLogId logId);

  /// Saves the daily log form. If offline, the form is queued and will be
  /// dispatched later when connectivity is restored.
  ///
  /// [ownerDriverId] — P0 2B-1: proven owner stored in the queued payload.
  /// Null = unproven (never inferred from the current session at dispatch).
  Future<Either<Failure, FormSaveResult>> saveForm({
    required DailyLogId logId,
    required DailyFormUpdate form,
    int? ownerDriverId,
  });

  /// Duty-status events of one daily log.
  ///
  /// Online: the official `GET /eld/daily-logs/{id}/events` (server is the
  /// source of truth). Offline / on failure: the last valid server snapshot,
  /// then locally recorded events of [date]. The returned snapshot names its
  /// source so the UI can distinguish a confirmed empty day from saved data,
  /// and a failed load with no valid data is returned as `Left` — never as an
  /// empty success.
  Future<Either<Failure, LogEventsSnapshot>> getEvents(
    DailyLogId logId,
    DateTime date,
  );

  /// Records a new manual duty-status event (`POST /eld/duty-status`).
  /// Falls back to the local store and offline queue when offline so nothing is lost (SRS 6.8).
  Future<Either<Failure, bool>> addEvent(
    LogEvent event, {
    String? reason,
    int? ownerDriverId,
  });

  /// Edits an existing manual event.
  ///
  /// Online, with a numeric event id and its parent [logId]: the unified
  /// `PUT /eld/daily-logs/{logId}/events/{eventId}` (`notes` carries the
  /// mandatory reason). Legacy/offline records without a parent log keep the
  /// old `POST /eld/duty-status` (UUID) or `PUT /eld/duty-status/{statusId}`
  /// paths. Server-rejected edits (automatic driving) are surfaced as a
  /// failure, never silently kept locally.
  /// تعديل حدث: يعيد الحدث **كما أكده الخادم** DTO، أو null إذا لم يُعِد
  /// الخادم جسماً (أحداث محلية/أوفلاين — حُفظت محلياً).
  Future<Either<Failure, LogEvent?>> updateEvent(
    LogEvent event, {
    required String reason,
    DailyLogId? logId,
    int? ownerDriverId,
  });
  Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId);

  /// حالة شاشة الاعتماد (`GET /eld/daily-logs/{id}/certify`).
  Future<Either<Failure, LogCertifyState>> getCertifyState(DailyLogId logId);

  /// يعتمد السجل قانونياً (`POST /eld/daily-logs/{id}/certify`).
  /// [signatureImageBase64] = صورة التوقيع المرسوم (PNG base64).
  ///
  /// يعيد [CertifySubmission.confirmed] فقط عندما تؤكد استجابة الخادم أن
  /// السجل أصبح معتمدًا، و[CertifySubmission.pendingSync] عندما يُحفظ الطلب
  /// في طابور الأوفلاين. استجابة غير حاسمة أو `certified=false` تعود
  /// `Left` كي تعرض الواجهة فشلاً قابلًا لإعادة المحاولة.
  Future<Either<Failure, CertifySubmission>> certifyLog({
    required DailyLogId logId,
    required int driverId,
    bool certified = true,
    String? signatureImageBase64,
    Map<String, dynamic>? device,
  });

  /// تفاصيل حدث خدمة محدد ضمن السجل اليومي والقيود التحريرية (`GET /eld/daily-logs/{id}/events/{eventId}`).
  Future<Either<Failure, Map<String, dynamic>?>> getEventDetails(
    DailyLogId logId,
    DutyStatusId eventId,
  );

  /// خيارات شاشة تعديل الأحداث والحالات المعتمدة (`GET /eld/daily-logs/{id}/events/options`).
  Future<Either<Failure, Map<String, dynamic>?>> getEventsOptions(
    DailyLogId logId,
  );

  /// مراجع وخيارات النموذج اليومي: مركبات وسائقون مساعدون (`GET /eld/daily-logs/{id}/form/options`).
  Future<Either<Failure, Map<String, dynamic>?>> getFormOptions(
    DailyLogId logId,
  );
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date);
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period);
  Future<Either<Failure, bool>> logAudit(AuditEntry entry);
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date);

  /// SRS 7.16: أحدث الأحداث للعرض في شاشة سجل التدقيق (قراءة فقط).
  Future<Either<Failure, List<AuditEntry>>> getRecentAuditEntries({
    int limit = 100,
  });

  /// مسودات التوقيع المؤقتة للحفاظ على توقيع السائق أثناء مراجعة التبويبات أو إغلاق الشاشة
  Future<void> saveDraftSignature(DailyLogId logId, String pointsJson);
  Future<String?> getDraftSignature(DailyLogId logId);
  Future<void> deleteDraftSignature(DailyLogId logId);
}

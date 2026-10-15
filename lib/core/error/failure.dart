import 'package:equatable/equatable.dart';

/// واجهة الفشل الأساسية
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  /// رسالة الخادم **القابلة للعرض** (إن أرسلها).
  ///
  /// تختلف عن [message] تماماً: [message] رمز آلي (`BUSINESS_RULE_VIOLATION`)
  /// مُخصَّص للسجلات، وهذا نصّ بشري مثل «السجل اليومي معتمد مسبقاً، لا يمكن
  /// تعديل بيانات النموذج قبل إلغاء الاعتماد».
  ///
  /// ⚠️ **لماذا هذا الحقل:** كان يُرمى في كل مسار. فكان السائق يرى
  /// «الخادم رفض الطلب» بينما الخادم كان قد كتب له سبباً دقيقاً ووقائياً.
  ///
  /// الأمان: لا يُعرض مباشرة — يمرّ على بوابة
  /// [_isSafeUserFacingText] في [anyErrorUserMessage] قبل الوصول للسائق.
  final String? serverMessage;

  const Failure({
    required this.message,
    this.statusCode,
    this.serverMessage,
  });

  @override
  List<Object?> get props => [message, statusCode, serverMessage];
}

/// فشل الخادم
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
    super.serverMessage,
  });
}

/// إخفاق مخصص عند انقطاع الإنترنت
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'noInternet',
  });
}

/// فشل المصادقة
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'sessionExpired',
  });
}

class MissingConfigurationFailure extends Failure {
  const MissingConfigurationFailure({
    super.message = 'serverNotConfigured',
  });
}

class InvalidConfigurationFailure extends Failure {
  const InvalidConfigurationFailure({
    super.message = 'invalidConfiguration',
  });
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'invalidCredentials',
  });
}

class SessionMissingFailure extends Failure {
  const SessionMissingFailure({
    super.message = 'sessionMissing',
  });
}

/// لا توجد لقطة لوحة محفوظة يمكن عرضها (جهاز بلا شبكة + لا كاش).
///
/// ⚠️ هذا الفشل مقصود: البديل القديم كان يُولّد ق��يم مُختلَقة
/// (offDuty + 11:00/14:00/70:00) فتُعرض كأنها رصيد قانوني حقيقي.
/// الآن يبني上层 اللوحة من المحرك المحلي، وإن تعذّر ذلك تُعرض
/// حالة "غير متاح" بدل أرقام ملفّقة.
class NoDashboardSnapshotFailure extends Failure {
  const NoDashboardSnapshotFailure({
    super.message = 'noDashboardSnapshot',
  });
}

/// لا يوجد ملخص أسبوعي محفوظ يمكن عرضه (جهاز بلا شبكة + لا كاش).
class NoRecapSnapshotFailure extends Failure {
  const NoRecapSnapshotFailure({
    super.message = 'noRecapSnapshot',
  });
}

/// فشل التخزين المؤقت
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
  });
}

/// فشل الصلاحيات
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
  });
}

/// فشل التتبع
class TrackingFailure extends Failure {
  const TrackingFailure({
    required super.message,
  });
}

/// فشل المزامنة
class SyncFailure extends Failure {
  const SyncFailure({
    required super.message,
  });
}

/// رفض نهائي من الخادم — إعادة الإرسال لن تنجح أبداً.
///
/// **لماذا هذا النوع موجود:** محرك المزامنة كان يطوي كل خطأ في
/// `ServerFailure` قابل لإعادة المحاولة، وبما أن `RetryPolicy`
/// مصمّمة عمداً لتعيد المحاولة إلى ما لا نهاية (قاعدة FMCSA:
/// لا تُفقد بيانات HOS)، فإن حدثاً مرفوضاً نهائياً — مثل
/// `409 BUSINESS_RULE_VIOLATION` على نموذج يوم **معتمد مسبقاً** —
/// كان يُعاد إرساله كل 50 ثانية إلى الأبد، بلا أي احتمال للنجاح.
///
/// **القاعدة:**
/// - أخطاء عابرة (شبكة، 5xx، 408، 429) ⇒ إعادة محاولة كما كانت.
/// - أخطاء نهائية (409، 400/422، 404، 403) ⇒ [RejectedFailure] ⇒
///   dead-letter فوراً مع سبب مقروء، ويُبلَّغ السائق.
///
/// **لا يعني الفقد:** التعارض من فعل السائق (اعتماد السجل)،
/// فإعادة إرسال طلب مرفوض ليست حماية للبيانات بل إغراق للسجلات
/// واستنزاف للشبكة وإخفاء فقد حقيقي عن عين السائق.
class RejectedFailure extends Failure {
  /// رمز الخطأ الآلي من الخادم (للتسجيل والتشخيص).
  final String code;

  /// رمز مترجم لعرضه للسائق.
  final String l10nKey;

  /// هل هذا الرفض نهائي (409/4xx) لا قابل للمحاولة مجدداً؟
  ///
  /// `true` لكل نسخ [RejectedFailure] الحالية — الحقل موجود ليعبّر عن
  /// النية صراحةً في السجل التشخيصي.
  final bool isPermanent;

  const RejectedFailure({
    required this.code,
    this.l10nKey = 'syncRejected',
    this.isPermanent = true,
  }) : super(message: 'sync.rejected');

  @override
  List<Object?> get props => [message, statusCode, code, l10nKey, isPermanent];
}

/// فشل التحقق من البيانات
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
  });
}

/// P0 2B-1 — حدث محجور لعدم تطابق الملكية (لا يُعاد إرساله تلقائياً).
/// يُنتَج حصراً من سياج الإرسال (مبكراً) أو رفض وقت-الإرسال، ويحوَّل في
/// المحرك إلى نقل ذري لجدول الحجر — لا حذف ولا retry.
class QuarantinedFailure extends Failure {
  /// سبب الحجر الآلي (للسجل التشخيصي فقط).
  final String reason;

  /// المالك المثبت للحدث وقت الحجر (null للمجهول).
  final int? ownerDriverId;

  /// اسم حالة التخزين المستهدفة (StoredEventState.name): إما صف مؤجل
  /// (يُعاد تقييمه) أو حجر مجهول (لا إفراج تلقائي). نصٌ لا نوع لتفادي
  /// اعتماد core على طبقة الميزات.
  final String parkState;

  const QuarantinedFailure({
    required this.reason,
    this.ownerDriverId,
    this.parkState = 'quarantinedUnknownOwner',
  }) : super(message: 'sync.quarantined');

  @override
  List<Object?> get props => [message, statusCode, reason, ownerDriverId, parkState];
}

/// P0 2B-1 — إشارة رفض وقت-الإرسال تُحمَل داخل DioException.
/// تحمل أعداداً فقط (المالك المتوقع والفعلي) — لا أسرار مصادقة أبداً.
class OwnerMismatchSignal {
  final int expectedOwnerDriverId;
  final int? actualOwnerDriverId;

  const OwnerMismatchSignal({
    required this.expectedOwnerDriverId,
    this.actualOwnerDriverId,
  });
}

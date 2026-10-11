import 'package:equatable/equatable.dart';

/// واجهة الفشل الأساسية
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// فشل الخادم
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
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

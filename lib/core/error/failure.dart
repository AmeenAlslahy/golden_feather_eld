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



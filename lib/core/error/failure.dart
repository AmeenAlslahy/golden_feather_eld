import 'package:equatable/equatable.dart';

/// واجهة الفشل الأساسية
abstract class Failure extends Equatable {
  final String message;
  final String? arabicMessage;
  final int? statusCode;

  const Failure({
    required this.message,
    this.arabicMessage,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, arabicMessage, statusCode];
}

/// فشل الخادم
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.arabicMessage,
    super.statusCode,
  });
}

/// إخفاق مخصص عند انقطاع الإنترنت
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'يرجى التحقق من اتصالك بالإنترنت',
    super.arabicMessage = 'لا يوجد اتصال بالإنترنت',
  });
}

/// فشل المصادقة
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'انتهت صلاحية الجلسة',
    super.arabicMessage = 'انتهت صلاحية الجلسة',
  });
}

class MissingConfigurationFailure extends Failure {
  const MissingConfigurationFailure({
    super.message = 'إعدادات الخادم مفقودة',
    super.arabicMessage = 'إعدادات الخادم مفقودة',
  });
}

class InvalidConfigurationFailure extends Failure {
  const InvalidConfigurationFailure({
    super.message = 'إعدادات الخادم غير صالحة',
    super.arabicMessage = 'إعدادات الخادم غير صالحة',
  });
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'بيانات الدخول غير صحيحة',
    super.arabicMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة',
  });
}

class SessionMissingFailure extends Failure {
  const SessionMissingFailure({
    super.message = 'الجلسة غير موجودة',
    super.arabicMessage = 'الجلسة غير موجودة، يرجى تسجيل الدخول',
  });
}

/// فشل التخزين المؤقت
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.arabicMessage,
  });
}

/// فشل الصلاحيات
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.arabicMessage,
  });
}

/// فشل التتبع
class TrackingFailure extends Failure {
  const TrackingFailure({
    required super.message,
    super.arabicMessage,
  });
}

/// فشل المزامنة
class SyncFailure extends Failure {
  const SyncFailure({
    required super.message,
    super.arabicMessage,
  });
}

/// فشل التحقق من البيانات
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.arabicMessage,
    this.fieldErrors,
  });
}



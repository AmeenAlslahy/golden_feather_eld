/// استثناء الخادم: يتم رميه عند وجود مشكلة في استجابة الخادم
class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  /// نص الخادم القابل للعرض (من `error.context['serverMessage']`).
  ///
  /// ⚠️ **يجب أن يُمرَّر عند الرمي.** فكان يُرفع `ServerException(message:
  /// error.code)` فقط، فيضيع السبب الدقيق ويصل السائق «الخادم رفض الطلب».
  final String? serverMessage;

  const ServerException({this.message, this.statusCode, this.serverMessage});

  @override
  String toString() => 'ServerException: $message';
}

/// استثناء عدم الاتصال: يتم رميه عند انقطاع الإنترنت أو انتهاء وقت الاتصال
class OfflineException implements Exception {
  final String? message;

  const OfflineException([this.message = 'Network error or timeout']);

  @override
  String toString() => 'OfflineException: $message';
}

/// استثناء عدم التصريح: يتم رميه عند مشاكل الصلاحيات أو انتهاء الجلسة (401/403)
class UnauthorizedException implements Exception {
  final String? message;
  final int? statusCode;

  const UnauthorizedException({
    this.message = 'Unauthorized',
    this.statusCode = 401,
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// استثناء الذاكرة المحلية: يتم رميه عند فشل حفظ أو قراءة البيانات من الجهاز
class CacheException implements Exception {
  final String? message;

  const CacheException([this.message]);

  @override
  String toString() => 'CacheException: $message';
}

/// استثناء المزامنة
class SyncException implements Exception {
  final String? message;

  const SyncException([this.message]);

  @override
  String toString() => 'SyncException: $message';
}

/// استثناء التتبع
class TrackingException implements Exception {
  final String? message;

  const TrackingException([this.message]);

  @override
  String toString() => 'TrackingException: $message';
}

/// استثناء الصلاحيات
class PermissionException implements Exception {
  final String? message;

  const PermissionException([this.message]);

  @override
  String toString() => 'PermissionException: $message';
}

import 'app_error.dart';
import 'failure.dart';

/// Message shown to the driver. Never the exception, stack, or `toString()`.
String anyErrorUserMessage(Object error, {required bool isArabic}) {
  if (error is AppError) return appErrorUserMessage(error, isArabic: isArabic);
  if (error is String) {
    final text = error.trim();
    if (text == 'noInternet') {
      return isArabic
          ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.'
          : 'No internet connection. Check the network and try again.';
    }
    if (text.isNotEmpty &&
        text.length <= 140 &&
        !_looksLikeServerDump(text) &&
        !text.contains('Instance of') &&
        !text.toLowerCase().contains('exception') &&
        !text.toLowerCase().contains('extension')) {
      return text;
    }
  }
  return isArabic
      ? 'تعذر إكمال الطلب. تحقق من الشبكة ثم أعد المحاولة.'
      : 'The request could not be completed. Check the network and try again.';
}

String appErrorUserMessage(AppError error, {required bool isArabic}) {
  final server = error.context?['serverMessage'];
  if (server is String &&
      server.trim().isNotEmpty &&
      !_looksLikeServerDump(server)) {
    return server.trim();
  }
  final nested = error.context?['message'];
  if (nested is String &&
      nested.trim().isNotEmpty &&
      !_looksLikeServerDump(nested)) {
    return nested.trim();
  }

  // Support legacy NetworkFailure messages
  if (error is NetworkFailure || (error is Failure && error.message == 'noInternet')) {
    return isArabic
        ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.'
        : 'No internet connection. Check the network and try again.';
  }

  return switch (error) {
    NetworkError() => isArabic
        ? 'تعذر الاتصال بالخادم. تحقق من الشبكة ثم أعد المحاولة.'
        : 'Could not reach the server. Check the network and try again.',
    ValidationError() => isArabic
        ? 'الخادم رفض الطلب.'
        : 'The server rejected this request.',
    SessionExpiredError() => isArabic
        ? 'انتهت الجلسة. سجّل الدخول مرة أخرى.'
        : 'The session expired. Sign in again.',
    PermissionError() => isArabic
        ? 'ليست لديك صلاحية لهذا الإجراء.'
        : 'You are not allowed to do this.',
    NotFoundError() => isArabic
        ? 'العنصر غير موجود على الخادم.'
        : 'The server did not find this item.',
    ServerError() => isArabic
        ? 'حدث خطأ في الخادم. أعد المحاولة.'
        : 'The server returned an error. Try again.',
    Failure() => isArabic
        ? 'تعذر إكمال الطلب. أعد المحاولة.'
        : 'The request could not be completed. Try again.',
    _ => isArabic
        ? 'تعذر إكمال الطلب.'
        : 'The request could not be completed.',
  };
}

bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('org.hibernate') ||
      lower.contains('org.postgresql') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('\tat ') ||
      text.length > 280;
}

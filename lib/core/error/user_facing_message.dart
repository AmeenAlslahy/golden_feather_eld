// lib/core/error/user_facing_message.dart
import 'app_error.dart';
import 'failure.dart';

/// Message shown to the driver. Never the exception, stack, or `toString()`.
String anyErrorUserMessage(Object error, {required bool isArabic}) {
  if (error is AppError) return appErrorUserMessage(error, isArabic: isArabic);
  if (error is Failure) {
    if (error is NetworkFailure || error.message == 'noInternet') {
      return isArabic
          ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.'
          : 'No internet connection. Check the network and try again.';
    }
    return isArabic
        ? 'تعذر إكمال الطلب. أعد المحاولة.'
        : 'The request could not be completed. Try again.';
  }
  if (error is String) {
    final text = error.trim();
    if (text == 'noInternet') {
      return isArabic
          ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.'
          : 'No internet connection. Check the network and try again.';
    }
    // Only accept strings that look like safe, curated messages.
    if (_isSafeUserFacingText(text)) return text;
  }
  return isArabic
      ? 'تعذر إكمال الطلب. تحقق من الشبكة ثم أعد المحاولة.'
      : 'The request could not be completed. Check the network and try again.';
}

String appErrorUserMessage(AppError error, {required bool isArabic}) {
  // Server-provided messages are only surfaced when they pass a strict
  // allow-list check (no PII, no stack dumps, no framework names).
  final server = error.context?['serverMessage'];
  if (server is String && _isSafeUserFacingText(server)) {
    return server.trim();
  }
  final nested = error.context?['message'];
  if (nested is String && _isSafeUserFacingText(nested)) {
    return nested.trim();
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
    _ => isArabic
        ? 'تعذر إكمال الطلب.'
        : 'The request could not be completed.',
  };
}

/// Strict gate: only curated, short, PII-free text reaches the driver.
///
/// Rejects anything that looks like a stack trace, framework dump, URL,
/// email, phone number, long identifier, or an over-long blob.
bool _isSafeUserFacingText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.length > 140) return false;
  if (_looksLikeServerDump(trimmed)) return false;
  if (_containsPii(trimmed)) return false;
  if (_containsUrl(trimmed)) return false;
  return true;
}

bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('hibernate') ||
      lower.contains('dioexception') ||
      lower.contains('org.postgresql') ||
      lower.contains('org.springframework') ||
      lower.contains('java.lang.') ||
      lower.contains('kotlin.') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('exception:') ||
      lower.contains('stacktrace') ||
      lower.contains('\tat ') ||
      lower.contains('instance of') ||
      lower.contains('package:');
}

/// Detects common PII shapes: emails, phones, long digit runs, UUIDs.
bool _containsPii(String text) {
  // Email
  if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(text)) return true;
  // Phone (7+ digits allowing separators)
  if (RegExp(r'\+?\d[\d\s\-\(\)]{6,}').hasMatch(text)) return true;
  // UUID
  if (RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
      .hasMatch(text)) {
    return true;
  }
  // Long digit run (IDs, tokens)
  if (RegExp(r'\d{8,}').hasMatch(text)) return true;
  return false;
}

bool _containsUrl(String text) {
  return RegExp(r'https?://', caseSensitive: false).hasMatch(text) ||
      RegExp(r'\bwww\.', caseSensitive: false).hasMatch(text);
}
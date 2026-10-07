// lib/core/error/user_facing_message.dart
import 'app_error.dart';
import 'failure.dart';
import '../../l10n/app_localizations.dart';

/// Message shown to the driver. Never the exception, stack, or `toString()`.
String anyErrorUserMessage(Object error, {required AppLocalizations loc}) {
  if (error is AppError) return appErrorUserMessage(error, loc: loc);
  if (error is Failure) {
    if (error is NetworkFailure || error.message == 'noInternet') {
      return loc.errNoInternet;
    }
    if (error is ServerFailure && error.message.isNotEmpty && _isSafeUserFacingText(error.message)) {
      return error.message;
    }
    return loc.errRequestFailed;
  }
  if (error is String) {
    final text = error.trim();
    if (text == 'noInternet') return loc.errNoInternet;
    // Only accept strings that look like safe, curated messages.
    if (_isSafeUserFacingText(text)) return text;
  }
  return loc.errRequestFailedNetwork;
}

String appErrorUserMessage(AppError error, {required AppLocalizations loc}) {
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
    NetworkError() => loc.errCannotReachServer,
    ValidationError() => loc.errServerRejected,
    SessionExpiredError() => loc.errSessionExpiredAction,
    PermissionError() => loc.errPermissionDenied,
    NotFoundError() => loc.errNotFound,
    ServerError() => loc.errServerError,
    _ => loc.errGeneric,
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
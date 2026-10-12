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
    if (error is ServerFailure && error.message.isNotEmpty) {
      final mapped = _mapTechnicalCode(error.message, loc);
      if (mapped != null) return mapped;
      if (_isSafeUserFacingText(error.message)) {
        return error.message;
      }
    }
    return loc.errRequestFailed;
  }
  if (error is String) {
    final text = error.trim();
    if (text == 'noInternet') return loc.errNoInternet;
    final mapped = _mapTechnicalCode(text, loc);
    if (mapped != null) return mapped;
    // Only accept strings that look like safe, curated messages.
    if (_isSafeUserFacingText(text)) return text;
  }
  return loc.errRequestFailedNetwork;
}

String appErrorUserMessage(AppError error, {required AppLocalizations loc}) {
  // Server-provided messages are only surfaced when they pass a strict
  // allow-list check (no PII, no stack dumps, no framework names).
  final server = error.context?['serverMessage'];
  if (server is String) {
    final mapped = _mapTechnicalCode(server, loc);
    if (mapped != null) return mapped;
    if (_isSafeUserFacingText(server)) return server.trim();
  }
  final nested = error.context?['message'];
  if (nested is String) {
    final mapped = _mapTechnicalCode(nested, loc);
    if (mapped != null) return mapped;
    if (_isSafeUserFacingText(nested)) return nested.trim();
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

/// Mappings for raw backend error codes or keys like 'validation.badRequest',
/// 'resource.conflict', 'noInternet', 'server.noResponse', etc.
String? _mapTechnicalCode(String code, AppLocalizations loc) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();

  if (lower == 'nointernet' ||
      lower.contains('network') ||
      lower.contains('no_internet')) {
    return loc.errNoInternet;
  }
  if (lower.contains('badrequest') ||
      lower.contains('validation') ||
      lower.contains('bad_request')) {
    return loc.errServerRejected;
  }
  if (lower.contains('notfound') || lower.contains('not_found')) {
    return loc.errNotFound;
  }
  if (lower.contains('unauthorized') ||
      lower.contains('forbidden') ||
      lower.contains('permission')) {
    return loc.errPermissionDenied;
  }
  if (lower.contains('session') || lower.contains('token_expired')) {
    return loc.errSessionExpiredAction;
  }
  if (lower.contains('conflict')) {
    return loc.errServerRejected;
  }
  if (lower.contains('server') || lower.contains('internal')) {
    return loc.errServerError;
  }
  if (_looksLikeTechnicalCode(trimmed)) {
    return loc.errRequestFailed;
  }
  return null;
}

bool _looksLikeTechnicalCode(String text) {
  final trimmed = text.trim();
  // Dot-separated codes like "validation.badRequest", "server.noResponse", etc.
  if (trimmed.contains('.') &&
      RegExp(r'^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_.-]+)+$').hasMatch(trimmed)) {
    return true;
  }
  // Single token with no spaces like "badRequest", "validationError", "UNAUTHORIZED"
  if (!trimmed.contains(' ') &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
    return true;
  }
  return false;
}

/// Strict gate: only curated, short, PII-free text reaches the driver.
///
/// Rejects anything that looks like a stack trace, framework dump, URL,
/// email, phone number, long identifier, or technical code/extension.
bool _isSafeUserFacingText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.length > 140) return false;
  if (_looksLikeServerDump(trimmed)) return false;
  if (_containsPii(trimmed)) return false;
  if (_containsUrl(trimmed)) return false;
  if (_looksLikeTechnicalCode(trimmed)) return false;
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
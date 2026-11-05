/// Maps transport-layer exceptions ([DioException]) to domain
/// [AppError] subclasses.
///
/// This is the **single point** where HTTP errors are translated.
/// Every adapter calls [mapDioException] in its catch blocks.
///
/// **Rule:** No adapter should catch `DioException` directly.
library;

import 'package:dio/dio.dart'; // ignore_architecture

import '../error/app_error.dart';
import '../utils/logger.dart';

/// Maps a [DioException] to the appropriate [AppError] subclass.
AppError mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkError(
        code: 'network.timeout',
        l10nKey: 'networkTimeout',
        cause: e,
        stackTrace: e.stackTrace,
        context: {'type': e.type.name, 'uri': e.requestOptions.uri.toString()},
      );

    case DioExceptionType.connectionError:
      return NetworkError(
        code: 'network.connectionFailed',
        l10nKey: 'networkConnectionFailed',
        cause: e,
        stackTrace: e.stackTrace,
        context: {'uri': e.requestOptions.uri.toString()},
      );

    case DioExceptionType.badCertificate:
      return NetworkError(
        code: 'network.badCertificate',
        l10nKey: 'networkBadCertificate',
        cause: e,
        stackTrace: e.stackTrace,
      );

    case DioExceptionType.cancel:
      return NetworkError(
        code: 'network.cancelled',
        l10nKey: 'networkCancelled',
        cause: e,
        stackTrace: e.stackTrace,
      );

    case DioExceptionType.badResponse:
      return _mapBadResponse(e);

    case DioExceptionType.unknown:
    default:
      if (e.error is FormatException) {
        return ServerError(
          code: 'server.malformedResponse',
          l10nKey: 'serverError',
          cause: e,
          stackTrace: e.stackTrace,
          context: {'uri': e.requestOptions.uri.toString()},
        );
      }
      return UnknownError(
        code: 'network.unknown',
        cause: e,
        stackTrace: e.stackTrace,
        context: {'uri': e.requestOptions.uri.toString()},
      );
  }
}

AppError _mapBadResponse(DioException e) {
  final response = e.response;
  if (response == null) {
    return ServerError(
      code: 'server.noResponse',
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  final statusCode = response.statusCode ?? 0;
  final serverMessage = _extractServerMessage(response.data);
  final serverErrorCode = _extractServerErrorCode(response.data);
  // الوثيقة (قاعدتا 3 و4): `errors[]` رسائل حقول موجهة للمستخدم، و
  // `requestId` يُحفظ في سجلات الأخطاء لتعقّب المعاملة لدى الدعم.
  final requestId = _extractRequestId(response.data);
  final fieldErrors = _extractFieldErrors(response.data);
  if (requestId != null) {
    AppLogger.warning(
      'HTTP $statusCode uri=${response.requestOptions.uri} '
      'requestId=$requestId'
      '${fieldErrors.isEmpty ? '' : ' fieldErrors=$fieldErrors'}',
    );
  }

  final context = <String, dynamic>{
    'statusCode': statusCode,
    'uri': response.requestOptions.uri.toString(),
    if (serverMessage != null) 'serverMessage': serverMessage,
    if (requestId != null) 'requestId': requestId,
    if (fieldErrors.isNotEmpty) 'fieldErrors': fieldErrors,
  };

  switch (statusCode) {
    case 400:
      final rawData = response.data?.toString().toLowerCase() ?? '';
      if (rawData.contains('excl_status_no_overlap') ||
          rawData.contains('no_overlap')) {
        return ConflictError(
          code: 'duty_status.overlap',
          l10nKey: 'eventTimeOverlap',
          cause: e,
          stackTrace: e.stackTrace,
          context: context,
        );
      }
      // DEBUG: print detailed errors array if present
      return ValidationError(
        code: serverErrorCode ?? 'validation.badRequest',
        l10nKey: 'validationError',
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 401:
      return SessionExpiredError(
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 403:
      return PermissionError(
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 404:
      return NotFoundError(
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 409:
      return ConflictError(
        code: serverErrorCode ?? 'resource.conflict',
        l10nKey: 'conflictError',
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 413:
      return ValidationError(
        code: 'validation.payloadTooLarge',
        l10nKey: 'fileTooLarge',
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 415:
      return ValidationError(
        code: 'validation.unsupportedMediaType',
        l10nKey: 'unsupportedFileType',
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 422:
      return ValidationError(
        code: serverErrorCode ?? 'validation.unprocessable',
        l10nKey: 'validationError',
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    case 503:
      return ServerError(
        code: 'server.unavailable',
        statusCode: statusCode,
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );

    default:
      if (statusCode >= 500) {
        return ServerError(
          code: 'server.$statusCode',
          statusCode: statusCode,
          cause: e,
          stackTrace: e.stackTrace,
          context: context,
        );
      }
      return UnknownError(
        code: 'network.http.$statusCode',
        cause: e,
        stackTrace: e.stackTrace,
        context: context,
      );
  }
}

String? _extractServerMessage(Object? data) {
  String? raw;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) raw = message.trim();
    if (raw == null) {
      // الوثيقة (قاعدة 3): رسالة أول خطأ حقلي موجهة للمستخدم مباشرة.
      final fieldError = _firstFieldErrorMessage(data['errors']);
      if (fieldError != null) raw = fieldError;
    }
    final error = data['error'];
    if (raw == null && error is String && error.trim().isNotEmpty) {
      raw = error.trim();
    }
  } else if (data is String && data.trim().isNotEmpty) {
    raw = data.trim();
  }
  if (raw == null) return null;
  if (_looksLikeServerDump(raw)) return null;
  return raw;
}

String? _firstFieldErrorMessage(Object? errors) {
  if (errors is! List) return null;
  for (final entry in errors) {
    if (entry is! Map) continue;
    final message = entry['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }
  return null;
}

/// `errors[{field, message, code}]` — نُبقيها كنصوص (field: message) في
/// سياق الخطأ لتظهر في السجلات ورسائل الدعم.
List<String> _extractFieldErrors(Object? data) {
  if (data is! Map) return const [];
  final errors = data['errors'];
  if (errors is! List) return const [];
  final result = <String>[];
  for (final entry in errors) {
    if (entry is! Map) continue;
    final field = entry['field']?.toString();
    final message = entry['message']?.toString();
    if (field == null || message == null || message.trim().isEmpty) continue;
    final code = entry['code']?.toString();
    result.add(code == null ? '$field: $message' : '$field ($code): $message');
  }
  return result;
}

String? _extractRequestId(Object? data) {
  if (data is! Map) return null;
  final requestId = data['requestId'];
  if (requestId is String && requestId.trim().isNotEmpty) {
    return requestId.trim();
  }
  return null;
}

bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('org.hibernate') ||
      lower.contains('org.postgresql') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('psqlexception') ||
      lower.contains('could not execute statement') ||
      lower.contains('\tat ') ||
      text.length > 280;
}

String? _extractServerErrorCode(Object? data) {
  if (data is! Map<String, dynamic>) return null;
  final code = data['error_code'] ?? data['errorCode'];
  if (code is String && code.isNotEmpty) return code;
  return null;
}

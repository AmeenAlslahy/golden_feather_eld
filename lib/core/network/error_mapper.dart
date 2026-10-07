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
        context: {
          'type': e.type.name,
          'uri': e.requestOptions.uri.toString(),
        },
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

  final context = <String, dynamic>{
    'statusCode': statusCode,
    'uri': response.requestOptions.uri.toString(),
    if (serverMessage != null) 'serverMessage': serverMessage,
  };

  switch (statusCode) {
    case 400:
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

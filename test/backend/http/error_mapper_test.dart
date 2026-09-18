import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/error_mapper.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';

void main() {
  RequestOptions requestOptions() => RequestOptions(
        path: '/eld/status',
        baseUrl: 'https://api.example.com',
      );

  group('mapDioException — network errors', () {
    test('connectionTimeout → NetworkError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.connectionTimeout,
      );

      final error = mapDioException(e);
      expect(error, isA<NetworkError>());
      expect(error.code, 'network.timeout');
      expect(error.severity, ErrorSeverity.warning);
    });

    test('connectionError → NetworkError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.connectionError,
      );

      final error = mapDioException(e);
      expect(error, isA<NetworkError>());
      expect(error.code, 'network.connectionFailed');
    });

    test('cancel → NetworkError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.cancel,
      );

      final error = mapDioException(e);
      expect(error, isA<NetworkError>());
      expect(error.code, 'network.cancelled');
    });

    test('badCertificate → NetworkError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badCertificate,
      );

      final error = mapDioException(e);
      expect(error, isA<NetworkError>());
    });

    test('unknown → UnknownError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.unknown,
      );

      final error = mapDioException(e);
      expect(error, isA<UnknownError>());
    });
  });

  group('mapDioException — HTTP errors', () {
    Response<dynamic> response(int status, [Object? body]) => Response(
          requestOptions: requestOptions(),
          statusCode: status,
          data: body,
        );

    test('400 → ValidationError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(400, {'message': 'Invalid input'}),
      );

      final error = mapDioException(e);
      expect(error, isA<ValidationError>());
      expect(error.severity, ErrorSeverity.warning);
    });

    test('400 with error_code extracts it', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(400, {
          'message': 'Invalid',
          'error_code': 'VALIDATION_EMAIL',
        }),
      );

      final error = mapDioException(e);
      expect(error.code, 'VALIDATION_EMAIL');
    });

    test('401 → SessionExpiredError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(401),
      );

      final error = mapDioException(e);
      expect(error, isA<SessionExpiredError>());
    });

    test('403 → PermissionError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(403),
      );

      final error = mapDioException(e);
      expect(error, isA<PermissionError>());
    });

    test('404 → NotFoundError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(404),
      );

      final error = mapDioException(e);
      expect(error, isA<NotFoundError>());
    });

    test('409 → ConflictError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(409, {'message': 'Already certified'}),
      );

      final error = mapDioException(e);
      expect(error, isA<ConflictError>());
    });

    test('413 → ValidationError (file too large)', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(413),
      );

      final error = mapDioException(e);
      expect(error, isA<ValidationError>());
      expect(error.code, 'validation.payloadTooLarge');
    });

    test('415 → ValidationError (unsupported media type)', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(415),
      );

      final error = mapDioException(e);
      expect(error, isA<ValidationError>());
      expect(error.code, 'validation.unsupportedMediaType');
    });

    test('500 → ServerError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(500),
      );

      final error = mapDioException(e);
      expect(error, isA<ServerError>());
      expect((error as ServerError).statusCode, 500);
      expect(error.code, 'server.500');
    });

    test('503 → ServerError with unavailable code', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(503),
      );

      final error = mapDioException(e);
      expect(error, isA<ServerError>());
      expect(error.code, 'server.unavailable');
    });

    test('unknown HTTP code → UnknownError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: response(418),
      );

      final error = mapDioException(e);
      expect(error, isA<UnknownError>());
    });

    test('badResponse without response object → ServerError', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
      );

      final error = mapDioException(e);
      expect(error, isA<ServerError>());
      expect(error.code, 'server.noResponse');
    });
  });

  group('mapDioException — context', () {
    test('includes URI in context', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.connectionTimeout,
      );

      final error = mapDioException(e);
      expect(error.context, containsPair('uri', contains('/eld/status')));
    });

    test('includes statusCode for HTTP errors', () {
      final e = DioException(
        requestOptions: requestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions(),
          statusCode: 500,
        ),
      );

      final error = mapDioException(e);
      expect(error.context, containsPair('statusCode', 500));
    });
  });
}

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ApiClient client;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    client = ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com'),
      dio: dio,
    );
  });

  group('ApiClient — GET', () {
    test('returns direct response', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {'driver': 'Ahmed'}),
      );

      final result = await client.get<Map<String, dynamic>>('/eld/status');

      expect(result.isSuccess, isTrue);
      result.tap(
        onSuccess: (response) {
          expect(response.isSuccess, isTrue);
          expect(response.data, {'driver': 'Ahmed'});
        },
      );
    });

    test('unwraps enveloped response', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {
          'code': 200,
          'status': true,
          'data': {'driver': 'Ahmed'},
        }),
      );

      final result = await client.get<Map<String, dynamic>>('/eld/status');

      result.tap(
        onSuccess: (response) {
          expect(response.data, {'driver': 'Ahmed'});
        },
      );
    });

    test('applies parser', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {'name': 'Ahmed'}),
      );

      final result = await client.get<String>(
        '/eld/status',
        parser: (data) => (data as Map)['name'] as String,
      );

      result.tap(
        onSuccess: (response) {
          expect(response.data, 'Ahmed');
        },
      );
    });

    test('returns NetworkError on timeout (retries disabled)', () async {
      final noRetryClient = ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.example.com'),
        dio: dio,
        maxRetries: 0,
      );
      adapter.onGet(
        '/eld/status',
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: '/eld/status'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      final result = await noRetryClient.get<dynamic>('/eld/status');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('returns SessionExpiredError on 401', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(401, {'message': 'Unauthorized'}),
      );

      final result = await client.get<dynamic>('/eld/status');

      expect(result.errorOrNull, isA<SessionExpiredError>());
    });

    test('returns ServerError on 500', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(500, {'message': 'Internal error'}),
      );

      final result = await client.get<dynamic>('/eld/status');

      expect(result.errorOrNull, isA<ServerError>());
    });
  });

  group('ApiClient — POST', () {
    test('sends body and parses response', () async {
      adapter.onPost(
        '/eld/duty-status',
        (server) => server.reply(200, {'id': 1, 'status': 'DRIVING'}),
        data: {'status': 'DRIVING'},
      );

      final result = await client.post<Map<String, dynamic>>(
        '/eld/duty-status',
        data: {'status': 'DRIVING'},
      );

      result.tap(
        onSuccess: (response) {
          expect(response.data, {'id': 1, 'status': 'DRIVING'});
        },
      );
    });

    test('empty 200 body is success, not FormatException', () async {
      adapter.onPost(
        '/eld/dot-inspection/start',
        (server) => server.reply(200, ''),
        data: Matchers.any,
      );

      final result = await client.post<Map<String, dynamic>>(
        '/eld/dot-inspection/start',
        data: {'driverId': 1},
        parser: (data) =>
            data is Map<String, dynamic> ? data : <String, dynamic>{},
      );

      expect(result.isSuccess, isTrue);
      result.tap(
        onSuccess: (response) {
          expect(response.isSuccess, isTrue);
        },
      );
    });

    test('handles 400 validation error', () async {
      adapter.onPost(
        '/eld/duty-status',
        (server) => server.reply(400, {
          'message': 'Validation failed',
          'error_code': 'INVALID_STATUS',
        }),
        data: {'status': 'INVALID'},
      );

      final result = await client.post<dynamic>(
        '/eld/duty-status',
        data: {'status': 'INVALID'},
      );

      expect(result.errorOrNull, isA<ValidationError>());
      expect(result.errorOrNull!.code, 'INVALID_STATUS');
    });
  });

  group('ApiClient — PUT', () {
    test('sends body and parses response', () async {
      adapter.onPut(
        '/eld/rules-screen',
        (server) => server.reply(200, {'cycleRule': 'USA 70/8'}),
        data: {'cycleRule': 'USA 70/8'},
      );

      final result = await client.put<Map<String, dynamic>>(
        '/eld/rules-screen',
        data: {'cycleRule': 'USA 70/8'},
      );

      result.tap(
        onSuccess: (response) {
          expect(response.data, {'cycleRule': 'USA 70/8'});
        },
      );
    });
  });

  group('ApiClient — DELETE', () {
    test('deletes and returns success', () async {
      adapter.onDelete('/eld/documents/1', (server) => server.reply(200, {}));

      final result = await client.delete<Map<String, dynamic>>(
        '/eld/documents/1',
      );

      result.tap(
        onSuccess: (response) {
          expect(response.isSuccess, isTrue);
        },
      );
    });
  });

  group('ApiClient — query parameters', () {
    test('includes query parameters', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {'driver': 'Ahmed'}),
        queryParameters: {'driverId': 101},
      );

      final result = await client.get<Map<String, dynamic>>(
        '/eld/status',
        queryParameters: {'driverId': 101},
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('ApiClient — custom headers', () {
    test('sends custom headers', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {'driver': 'Ahmed'}),
        headers: {'X-Custom': 'value'},
      );

      final result = await client.get<Map<String, dynamic>>(
        '/eld/status',
        headers: {'X-Custom': 'value'},
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('ApiClient — download', () {
    test('returns bytes on success', () async {
      final bytes = [1, 2, 3, 4, 5];
      adapter.onGet(
        '/eld/reports/101/pdf',
        (server) => server.reply(200, Uint8List.fromList(bytes)),
      );

      final result = await client.download('/eld/reports/101/pdf');

      result.tap(
        onSuccess: (data) {
          expect(data, isA<Uint8List>());
          expect(data, equals(Uint8List.fromList(bytes)));
        },
      );
    });

    test('returns error on 404', () async {
      adapter.onGet(
        '/eld/reports/999/pdf',
        (server) => server.reply(404, 'Not found'),
      );

      final result = await client.download('/eld/reports/999/pdf');

      expect(result.errorOrNull, isA<NotFoundError>());
    });
  });

  group('ApiClient — uploadFile', () {
    test('uploads multipart', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);

      adapter.onPost(
        '/eld/documents/101/upload-file',
        (server) => server.reply(201, {'id': 42, 'fileName': 'doc.pdf'}),
        data: Matchers.any,
      );

      final result = await client.uploadFile<Map<String, dynamic>>(
        '/eld/documents/101/upload-file',
        fileBytes: bytes,
        fieldName: 'document',
        fileName: 'doc.pdf',
      );

      result.tap(
        onSuccess: (response) {
          expect(response.data, {'id': 42, 'fileName': 'doc.pdf'});
        },
      );
    });
  });

  group('ApiClient — configuration', () {
    test('normalizes base URL', () {
      final client = ApiClient(
        config: const ApiConfig(baseUrl: 'api.example.com/'),
        dio: Dio(),
      );

      expect(client.dio.options.baseUrl, 'https://api.example.com');
    });

    test('applies timeouts', () {
      final client = ApiClient(
        config: const ApiConfig(
          baseUrl: 'https://api.example.com',
          connectTimeout: Duration(seconds: 45),
          receiveTimeout: Duration(seconds: 60),
        ),
        dio: Dio(),
      );

      expect(client.dio.options.connectTimeout, const Duration(seconds: 45));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 60));
    });

    test('applies default headers', () {
      final client = ApiClient(
        config: const ApiConfig(
          baseUrl: 'https://api.example.com',
          defaultHeaders: {'Accept': 'application/json', 'X-Version': '1.0'},
        ),
        dio: Dio(),
      );

      expect(client.dio.options.headers, {
        'Accept': 'application/json',
        'X-Version': '1.0',
      });
    });
  });

  group('ApiClient — retry & cancellation', () {
    // http_mock_adapter's route handler is evaluated once at registration
    // (a later registration of the same route replaces the earlier one), so
    // `replyCallback` — whose data callback runs per request — is the way
    // to both count attempts and vary the outcome.
    ApiClient fastRetryClient(Dio dio) => ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com'),
      dio: dio,
      // Zero backoff keeps these tests deterministic and fast.
      retryBackoff: Duration.zero,
    );

    DioException transientTimeout(String path) => DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionTimeout,
    );

    test(
      'GET retries a transient timeout and succeeds on the next attempt',
      () async {
        final retryDio = Dio();
        final retryAdapter = DioAdapter(dio: retryDio);
        final client = fastRetryClient(retryDio);
        var attempts = 0;

        retryAdapter.onGet('/eld/status', (server) {
          server.replyCallback(200, (options) {
            attempts++;
            if (attempts == 1) {
              throw transientTimeout('/eld/status');
            }
            return {'driver': 'Ahmed'};
          });
        });

        final result = await client.get<Map<String, dynamic>>('/eld/status');

        expect(result.isSuccess, isTrue);
        expect(attempts, 2);
        result.tap(
          onSuccess: (response) {
            expect(response.data, {'driver': 'Ahmed'});
          },
        );
      },
    );

    test('GET stops after maxRetries and maps the last error', () async {
      final retryDio = Dio();
      final retryAdapter = DioAdapter(dio: retryDio);
      final client = fastRetryClient(retryDio);
      var attempts = 0;

      retryAdapter.onGet('/eld/status', (server) {
        server.replyCallback(200, (options) {
          attempts++;
          throw transientTimeout('/eld/status');
        });
      });

      final result = await client.get<dynamic>('/eld/status');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
      // 1 original attempt + 2 retries.
      expect(attempts, 3);
    });

    test('GET never retries a server decision (500)', () async {
      var attempts = 0;
      adapter.onGet('/eld/status', (server) {
        server.replyCallback(500, (options) {
          attempts++;
          return {'message': 'Internal error'};
        });
      });

      final result = await client.get<dynamic>('/eld/status');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ServerError>());
      expect(attempts, 1);
    });

    test('POST is never retried, even on a transient timeout', () async {
      var attempts = 0;
      adapter.onPost('/eld/duty-status', (server) {
        server.replyCallback(200, (options) {
          attempts++;
          throw transientTimeout('/eld/duty-status');
        });
      }, data: Matchers.any);

      final result = await client.post<dynamic>(
        '/eld/duty-status',
        data: {'status': 'DRIVING'},
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
      expect(attempts, 1);
    });

    test('a cancelled request maps to a NetworkError', () async {
      final token = CancelToken()..cancel();
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {'driver': 'Ahmed'}),
      );

      final result = await client.get<dynamic>(
        '/eld/status',
        cancelToken: token,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkError>());
    });
  });
}

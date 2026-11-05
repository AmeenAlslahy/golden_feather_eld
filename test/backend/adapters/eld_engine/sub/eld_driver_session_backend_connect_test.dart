import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_driver_session_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

/// Builds the live adapter with a locally resolved response.
EldDriverSessionBackend backendReplying(
  Object? body, {
  int statusCode = 200,
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
        );
      },
    ),
  );
  return EldDriverSessionBackend(
    ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
      dio: dio,
    ),
  );
}

/// Lets the test decide resolve/reject per request path.
EldDriverSessionBackend backendHandling(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
  onRequest,
) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
  return EldDriverSessionBackend(
    ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
      dio: dio,
    ),
  );
}

void main() {
  group('EldDriverSessionBackend.connect — success', () {
    test(
      'sends the contract body with no query parameters and unwraps data',
      () async {
        RequestOptions? captured;
        final backend = backendReplying({
          'success': true,
          'data': {'id': 7, 'driverId': 101, 'status': 'ACTIVE'},
        }, onRequest: (options) => captured = options);

        final result = await backend.connect(
          uniqueId: 'AA:BB:CC:DD:EE:FF',
          driverId: const DriverId(101),
          coDriverId: const DriverId(202),
        );

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, {
          'id': 7,
          'driverId': 101,
          'status': 'ACTIVE',
        });
        expect(captured?.method, 'POST');
        expect(captured?.uri.path, '/api/eld/sessions/connect');
        expect(captured?.queryParameters, isEmpty);
        expect(captured?.data, {
          'driverId': 101,
          'coDriverId': 202,
          'deviceId': 'AA:BB:CC:DD:EE:FF',
          'manualMode': false,
          'manualModeEnabled': true,
        });
      },
    );

    test('disconnected mode sends manualMode=true', () async {
      RequestOptions? captured;
      final backend = backendReplying({
        'success': true,
        'data': {'id': 8, 'status': 'ACTIVE'},
      }, onRequest: (options) => captured = options);

      final result = await backend.connect(
        uniqueId: '44A4',
        disconnected: true,
      );

      expect(result.isSuccess, isTrue);
      expect(captured?.queryParameters, isEmpty);
      expect(captured?.data, {
        'deviceId': '44A4',
        'manualMode': true,
        'manualModeEnabled': true,
      });
    });
  });

  group('EldDriverSessionBackend.connect — failure', () {
    test('non-2xx surfaces the mapped transport error', () async {
      final paths = <String>[];
      final backend = backendHandling((options, handler) {
        paths.add(options.uri.path);
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 500,
              data: {'message': 'boom'},
            ),
          ),
        );
      });

      final result = await backend.connect(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ServerError>());
      expect(paths, ['/api/eld/sessions/connect']);
    });
  });

  group('EldDriverSessionBackend.connect — invalid response', () {
    // NOTE: these lock in the pre-existing lenient behavior of this path.
    // Converting an unusable body into `{}` instead of an error is a separate
    // issue and is intentionally NOT unified with the hardware path here.
    test(
      'non-object envelope data becomes an empty successful payload',
      () async {
        final backend = backendReplying({'success': true, 'data': 'ok'});

        final result = await backend.connect(uniqueId: '44A4');

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isEmpty);
      },
    );

    test('envelope without data becomes an empty successful payload', () async {
      final backend = backendReplying({'success': true, 'message': 'accepted'});

      final result = await backend.connect(uniqueId: '44A4');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test(
      'a non-typed map body is discarded, unlike the hardware path',
      () async {
        final backend = backendReplying(<dynamic, dynamic>{'id': 7});

        final result = await backend.connect(uniqueId: '44A4');

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isEmpty);
      },
    );
  });

  group('EldDriverSessionBackend.connect — /start fallback on 404', () {
    void rejectNotFound(
      RequestOptions options,
      RequestInterceptorHandler handler,
    ) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'not found'},
          ),
        ),
      );
    }

    test('404 from /connect retries /start with the same payload', () async {
      final paths = <String>[];
      final payloads = <Object?>[];

      final backend = backendHandling((options, handler) {
        paths.add(options.uri.path);
        payloads.add(options.data);
        if (options.uri.path.endsWith('/sessions/connect')) {
          rejectNotFound(options, handler);
          return;
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {'id': 9, 'status': 'ACTIVE'},
            },
          ),
        );
      });

      final result = await backend.connect(
        uniqueId: '44A4',
        driverId: const DriverId(101),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['id'], 9);
      expect(paths, ['/api/eld/sessions/connect', '/api/eld/sessions/start']);
      expect(payloads[0], payloads[1]);
      expect(payloads[1], {
        'driverId': 101,
        'deviceId': '44A4',
        'manualMode': false,
        'manualModeEnabled': true,
      });
    });

    test('both routes returning 404 surfaces NotFoundError', () async {
      final paths = <String>[];
      final backend = backendHandling((options, handler) {
        paths.add(options.uri.path);
        rejectNotFound(options, handler);
      });

      final result = await backend.connect(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NotFoundError>());
      expect(paths, ['/api/eld/sessions/connect', '/api/eld/sessions/start']);
    });
  });
}

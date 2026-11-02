import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_hardware_backend.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';

/// Builds a live-adapter instance whose HTTP response is resolved locally.
/// No network, server, or device is touched.
EldHardwareBackend backendReplying(
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
  return EldHardwareBackend(
    ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
      dio: dio,
    ),
  );
}

void main() {
  group('EldHardwareBackend.connectSession — confirmed success', () {
    test(
      'sends the existing query/body and unwraps a non-empty envelope data',
      () async {
        RequestOptions? captured;
        final backend = backendReplying({
          'success': true,
          'data': {'id': 7, 'driverId': 101, 'status': 'ACTIVE'},
          'requestId': 'req-123',
        }, onRequest: (options) => captured = options);

        final result = await backend.connectSession(
          uniqueId: 'AA:BB:CC:DD:EE:FF',
        );

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, {
          'id': 7,
          'driverId': 101,
          'status': 'ACTIVE',
        });
        expect(captured?.method, 'POST');
        expect(captured?.uri.path, '/api/eld/sessions/connect');
        expect(captured?.queryParameters, {'uniqueId': 'AA:BB:CC:DD:EE:FF'});
        expect(captured?.data, {
          'deviceId': 'AA:BB:CC:DD:EE:FF',
          'manualMode': false,
          'manualModeEnabled': false,
        });
      },
    );

    test('accepts a direct non-empty session object', () async {
      final backend = backendReplying({
        'id': 7,
        'driverId': 101,
        'status': 'ACTIVE',
      });

      final result = await backend.connectSession(uniqueId: '44A4');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['id'], 7);
    });

    test('keeps the disconnected payload flags unchanged', () async {
      RequestOptions? captured;
      final backend = backendReplying({
        'success': true,
        'data': {'id': 8, 'status': 'ACTIVE', 'manualMode': true},
      }, onRequest: (options) => captured = options);

      final result = await backend.connectSession(
        uniqueId: '44A4',
        disconnected: true,
      );

      expect(result.isSuccess, isTrue);
      expect(captured?.queryParameters, {
        'uniqueId': '44A4',
        'disconnected': true,
      });
      expect(captured?.data, {
        'deviceId': '44A4',
        'manualMode': true,
        'manualModeEnabled': true,
      });
    });
  });

  group('EldHardwareBackend.connectSession — explicit rejection', () {
    test('treats the bare {"success":false} body as failure', () async {
      final backend = backendReplying({'success': false});

      final result = await backend.connectSession(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull!;
      expect(error.code, 'eld.session.connectRejected');
      expect(error.context?['reason'], 'success_false');
    });

    test('explicit success:false wins even when data is present', () async {
      final backend = backendReplying({
        'success': false,
        'data': {'id': 7},
        'requestId': 'req-rejected',
      });

      final result = await backend.connectSession(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, 'eld.session.connectRejected');
      expect(result.errorOrNull?.context?['requestId'], 'req-rejected');
    });

    test('legacy status:false is a rejection', () async {
      final backend = backendReplying({
        'code': 200,
        'status': false,
        'message': 'not connected',
      });

      final result = await backend.connectSession(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, 'eld.session.connectRejected');
      expect(result.errorOrNull?.context?['reason'], 'status_false');
    });

    test('non-2xx status is a rejection', () async {
      final backend = backendReplying({'message': 'error'}, statusCode: 500);

      final result = await backend.connectSession(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, 'eld.session.connectRejected');
    });
  });

  group('EldHardwareBackend.connectSession — unconfirmed payload', () {
    Future<void> expectUnconfirmed(Object? body, {String? requestId}) async {
      final backend = backendReplying(body);
      final result = await backend.connectSession(uniqueId: '44A4');

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull!;
      expect(error.code, 'eld.session.connectUnconfirmed');
      expect(error.context?['reason'], 'missing_or_malformed_data');
      if (requestId != null) {
        expect(error.context?['requestId'], requestId);
      }
    }

    test('bare success:true without data', () async {
      await expectUnconfirmed({'success': true});
    });

    test('data:null', () async {
      await expectUnconfirmed({'success': true, 'data': null});
    });

    test('empty data object', () async {
      await expectUnconfirmed({'success': true, 'data': <String, dynamic>{}});
    });

    test('non-object data', () async {
      await expectUnconfirmed({'success': true, 'data': 'ok'});
    });

    test('empty body object', () async {
      await expectUnconfirmed(<String, dynamic>{});
    });

    test('data-only body with empty object', () async {
      await expectUnconfirmed({'data': <String, dynamic>{}});
    });

    test('preserves requestId without exposing the response body', () async {
      await expectUnconfirmed({
        'success': true,
        'requestId': 'req-unconfirmed',
      }, requestId: 'req-unconfirmed');
    });
  });
}

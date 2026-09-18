import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_health_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_config.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late EldHealthBackend backend;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    backend = EldHealthBackend(
      ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
        dio: dio,
      ),
    );
  });

  group('EldHealthBackend.checkLiveness', () {
    test('returns success on 200', () async {
      adapter.onGet(
        '/eld/health',
        (server) => server.reply(200, {}),
      );

      final result = await backend.checkLiveness();

      expect(result.isSuccess, isTrue);
    });

    test('returns error on 500', () async {
      adapter.onGet(
        '/eld/health',
        (server) => server.reply(500, {'message': 'Server error'}),
      );

      final result = await backend.checkLiveness();

      expect(result.errorOrNull, isA<ServerError>());
    });
  });

  group('EldHealthBackend.checkDetailed', () {
    test('returns raw data on 200', () async {
      adapter.onGet(
        '/eld/health/detailed',
        (server) => server.reply(200, {
          'database': {'status': 'ok'},
          'storage': {'writable': true},
        }),
      );

      final result = await backend.checkDetailed();

      result.tap(onSuccess: (data) {
        expect(data, isA<Map<String, dynamic>>());
        expect(data['database'], isNotNull);
      });
    });
  });
}

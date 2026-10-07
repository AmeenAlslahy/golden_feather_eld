import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_account_backend.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

const _mockAccountJson = {
  'driverId': 101,
  'email': 'driver@example.com',
  'phone': '123-456-7890',
  'carrier': 'Carrier Inc',
  'mainOfficeAddress': '123 Main St',
  'homeTerminalAddress': '456 Home St',
  'timeZone': 'America/New_York',
  'language': 'English',
  'odometer': 'mi',
  'license': {
    'state': 'NY',
    'number': '123456789',
    'formatted': 'NY-123456789'
  }
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late EldAccountBackend backend;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    backend = EldAccountBackend(
      ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
        dio: dio,
      ),
    );
  });

  group('EldAccountBackend.getMyAccount', () {
    test('works without driverId', () async {
      adapter.onGet(
        '/eld/account',
        (server) => server.reply(200, _mockAccountJson),
      );

      final result = await backend.getMyAccount();

      result.tap(onSuccess: (data) {
        expect(data.language, 'English');
      });
    });

    test('passes driverId as query parameter', () async {
      adapter.onGet(
        '/eld/account',
        (server) => server.reply(200, _mockAccountJson),
        queryParameters: {'driverId': 101},
      );

      final result = await backend.getMyAccount(
        driverId: const DriverId(101),
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('EldAccountBackend.updatePreferences', () {
    test('sends language and odometer', () async {
      adapter.onPut(
        '/eld/account/preferences',
        (server) => server.reply(200, {
          ..._mockAccountJson,
          'language': 'ar',
          'odometer': 'km',
        }),
        data: {'language': 'ar', 'odometer': 'km'},
      );

      final result = await backend.updatePreferences(
        language: 'ar',
        odometerUnit: 'km',
      );

      result.tap(onSuccess: (data) {
        expect(data.language, 'ar');
      });
    });
  });
}

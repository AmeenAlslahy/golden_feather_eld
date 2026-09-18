import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_account_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_config.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

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

  group('EldAccountBackend.getProfile', () {
    test('requests correct path', () async {
      adapter.onGet(
        '/eld/profile/101',
        (server) => server.reply(200, {
          'id': 101,
          'name': 'Ahmed',
          'email': 'ahmed@eld.com',
        }),
      );

      final result = await backend.getProfile(const DriverId(101));

      result.tap(onSuccess: (data) {
        expect(data['name'], 'Ahmed');
      });
    });

    test('returns error on 404', () async {
      adapter.onGet(
        '/eld/profile/999',
        (server) => server.reply(404, {'message': 'Not found'}),
      );

      final result = await backend.getProfile(const DriverId(999));

      expect(result.errorOrNull, isA<NotFoundError>());
    });
  });

  group('EldAccountBackend.updateProfile', () {
    test('sends PUT to correct path', () async {
      adapter.onPut(
        '/eld/profile/101',
        (server) => server.reply(200, {
          'id': 101,
          'name': 'Updated',
        }),
        data: {'name': 'Updated'},
      );

      final result = await backend.updateProfile(
        driverId: const DriverId(101),
        update: {'name': 'Updated'},
      );

      result.tap(onSuccess: (data) {
        expect(data['name'], 'Updated');
      });
    });
  });

  group('EldAccountBackend.getMyAccount', () {
    test('works without driverId', () async {
      adapter.onGet(
        '/eld/account',
        (server) => server.reply(200, {'name': 'Me'}),
      );

      final result = await backend.getMyAccount();

      result.tap(onSuccess: (data) {
        expect(data['name'], 'Me');
      });
    });

    test('passes driverId as query parameter', () async {
      adapter.onGet(
        '/eld/account',
        (server) => server.reply(200, {'name': 'Me'}),
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
        (server) => server.reply(200, {'language': 'ar', 'odometer': 'km'}),
        data: {'language': 'ar', 'odometer': 'km'},
      );

      final result = await backend.updatePreferences(
        language: 'ar',
        odometerUnit: 'km',
      );

      result.tap(onSuccess: (data) {
        expect(data['language'], 'ar');
      });
    });
  });
}

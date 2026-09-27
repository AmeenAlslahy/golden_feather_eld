import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_auth_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';

void main() {
  test('login uses form session and keeps only JSESSIONID', () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        captured = options;
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: '{"token":"not-a-session","email":"driver@example.com"}',
          headers: Headers.fromMap({
            'set-cookie': ['JSESSIONID=session-1; Path=/; HttpOnly'],
          }),
        ));
      },
    ));
    final backend = EldAuthBackend(ApiClient(
      config: const ApiConfig(baseUrl: 'https://snsoft.cloud/api'),
      dio: dio,
    ));

    final result = await backend.login(
      identifier: 'driver@example.com',
      password: 'secret',
      serverUrl: 'https://snsoft.cloud',
      backendType: 'eld',
    );

    expect(captured?.uri.toString(), 'https://snsoft.cloud/api/session');
    expect(captured?.contentType, 'application/x-www-form-urlencoded');
    expect(captured?.data, {
      'email': 'driver@example.com',
      'password': 'secret',
    });
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?['credential'], 'session-1');
  });

  test('login fails closed when the session cookie is absent', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: '{"token":"bearer-looking"}',
        ));
      },
    ));
    final backend = EldAuthBackend(ApiClient(
      config: const ApiConfig(baseUrl: 'https://snsoft.cloud/api'),
      dio: dio,
    ));

    final result = await backend.login(
      identifier: 'driver@example.com',
      password: 'secret',
      serverUrl: 'https://snsoft.cloud',
      backendType: 'eld',
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.code, 'missing_credential');
  });
}

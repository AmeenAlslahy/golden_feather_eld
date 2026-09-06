import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:golden_feather_eld/core/network/endpoints/traccar_endpoints.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:golden_feather_eld/core/error/exception.dart';

class FakeDioAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, dynamic> responseData = {};
  Map<String, List<String>> headers = {};
  bool throwException = false;
  DioException? exceptionToThrow;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwException) {
      throw exceptionToThrow ?? DioException(requestOptions: options);
    }
    return ResponseBody.fromString(
      jsonEncode(responseData),
      statusCode,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late FakeDioAdapter fakeAdapter;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeAdapter = FakeDioAdapter();
    dio = Dio()..httpClientAdapter = fakeAdapter;
    dataSource = AuthRemoteDataSourceImpl(dio, TraccarEndpoints());
  });

  group('AuthRemoteDataSource - Login', () {
    const serverUrl = 'https://traccar.invalid:5055';
    const email = 'test@example.com';
    const password = 'password123';
    const expectedOrigin = 'https://traccar.invalid:5055';

    test('should return AuthSession when login is successful and JSESSIONID is present', () async {
      fakeAdapter.statusCode = 200;
      fakeAdapter.responseData = {'id': 1, 'name': 'Test User'};
      fakeAdapter.headers = {
        'set-cookie': ['JSESSIONID=node01fakecookieabc; Path=/; HttpOnly'],
        'content-type': ['application/json'],
      };

      final result = await dataSource.login(email: email, password: password, serverUrl: serverUrl, backendType: 'traccar');

      expect(result.serverOrigin, expectedOrigin);
      expect(result.sessionCredential, 'node01fakecookieabc');
      expect(result.userMetadata['name'], 'Test User');
    });

    test('should throw ServerException when status is 401', () async {
      fakeAdapter.statusCode = 401;
      fakeAdapter.responseData = {};
      fakeAdapter.headers = {'content-type': ['application/json']};

      expect(
        () => dataSource.login(email: email, password: password, serverUrl: serverUrl, backendType: 'traccar'),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('should throw ServerException when Set-Cookie is missing', () async {
      fakeAdapter.statusCode = 200;
      fakeAdapter.responseData = {'id': 1};
      fakeAdapter.headers = {'content-type': ['application/json']};

      expect(
        () => dataSource.login(email: email, password: password, serverUrl: serverUrl, backendType: 'traccar'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Missing session credential from server')),
      );
    });
  });
}

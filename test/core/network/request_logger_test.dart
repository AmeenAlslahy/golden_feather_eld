import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/network/request_logger.dart';

void main() {
  group('RequestLogger Redaction Tests', () {
    late RequestLogger logger;

    setUp(() {
      logger = RequestLogger();
    });

    test('logger does not crash on complex nested maps', () {
      final options = RequestOptions(path: '/session', data: {
        'email': 'test@test.com',
        'password': 'TEST_PASSWORD_123',
        'nested': {'token': 'TEST_TOKEN_ABC', 'normal': 'value'},
        'list': [
          {'jsessionid': 'TEST_JSESSIONID_XYZ'}
        ]
      }, headers: {
        'Cookie': 'JSESSIONID=TEST_JSESSIONID_XYZ',
        'Authorization': 'Bearer TEST_TOKEN_ABC',
      });

      final handler = RequestInterceptorHandler();
      expect(() => logger.onRequest(options, handler), returnsNormally);
    });
  });
}

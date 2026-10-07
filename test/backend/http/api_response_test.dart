import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';

void main() {
  group('ApiResponse — direct response', () {
    test('parses map body without envelope', () {
      final response = ApiResponse.fromBody<Map<String, dynamic>>(
        statusCode: 200,
        rawBody: {'id': 42, 'name': 'Driver'},
      );

      expect(response.statusCode, 200);
      expect(response.isSuccess, isTrue);
      expect(response.data, {'id': 42, 'name': 'Driver'});
      expect(response.message, isNull);
      expect(response.errorCode, isNull);
    });

    test('parses list body without envelope', () {
      final response = ApiResponse.fromBody<List<dynamic>>(
        statusCode: 200,
        rawBody: [
          {'id': 1},
          {'id': 2},
        ],
      );

      expect(response.isSuccess, isTrue);
      expect(response.data, hasLength(2));
    });

    test('4xx response is not success', () {
      final response = ApiResponse.fromBody<Map<String, dynamic>>(
        statusCode: 400,
        rawBody: {'message': 'Bad request'},
      );

      expect(response.isSuccess, isFalse);
    });

    test('5xx response is not success', () {
      final response = ApiResponse.fromBody<dynamic>(
        statusCode: 500,
        rawBody: null,
      );

      expect(response.isSuccess, isFalse);
    });
  });

  group('ApiResponse — enveloped response', () {
    test('unwraps data field', () {
      final response = ApiResponse.fromBody<Map<String, dynamic>>(
        statusCode: 200,
        rawBody: {
          'code': 200,
          'status': true,
          'data': {'id': 42},
          'message': 'Success',
        },
      );

      expect(response.statusCode, 200);
      expect(response.isSuccess, isTrue);
      expect(response.data, {'id': 42});
      expect(response.message, 'Success');
    });

    test('detects envelope status=false as failure', () {
      final response = ApiResponse.fromBody<Map<String, dynamic>>(
        statusCode: 200,
        rawBody: {
          'code': 200,
          'status': false,
          'data': null,
          'message': 'Login failed',
          'error': 'INVALID_CREDENTIALS',
        },
      );

      expect(response.isSuccess, isFalse);
      expect(response.message, 'Login failed');
      expect(response.errorCode, 'INVALID_CREDENTIALS');
    });

    test('extracts server error code', () {
      final response = ApiResponse.fromBody<dynamic>(
        statusCode: 400,
        rawBody: {
          'code': 400,
          'status': false,
          'data': null,
          'message': 'Validation failed',
          'error': 'VALIDATION_EMAIL_INVALID',
        },
      );

      expect(response.errorCode, 'VALIDATION_EMAIL_INVALID');
      expect(response.message, 'Validation failed');
    });

    test('applies parser to unwrapped data', () {
      final response = ApiResponse.fromBody<String>(
        statusCode: 200,
        rawBody: {
          'code': 200,
          'status': true,
          'data': {'name': 'Ahmed'},
        },
        parser: (data) => (data as Map)['name'] as String,
      );

      expect(response.data, 'Ahmed');
    });

    test('handles null data', () {
      final response = ApiResponse.fromBody<dynamic>(
        statusCode: 200,
        rawBody: {
          'code': 200,
          'status': true,
          'data': null,
        },
      );

      expect(response.data, isNull);
      expect(response.isSuccess, isTrue);
    });
  });

  group('ApiResponse — false positive prevention', () {
    test('map with code but no status is direct response', () {
      final response = ApiResponse.fromBody<Map<String, dynamic>>(
        statusCode: 200,
        rawBody: {
          'code': 'ABC',
          'name': 'Domain object',
        },
      );

      // Should NOT be treated as envelope.
      expect(response.data, {'code': 'ABC', 'name': 'Domain object'});
    });

    test('map with status but no code is direct response', () {
      final response = ApiResponse.fromBody<Map<String, dynamic>>(
        statusCode: 200,
        rawBody: {
          'status': 'ACTIVE',
          'name': 'Driver',
        },
      );

      expect(response.data, {'status': 'ACTIVE', 'name': 'Driver'});
    });
  });

  group('ApiResponse — withData', () {
    test('replaces data while preserving metadata', () {
      const original = ApiResponse<int>(
        statusCode: 200,
        isSuccess: true,
        data: 42,
        message: 'OK',
      );

      final transformed = original.withData<String>('hello');

      expect(transformed.data, 'hello');
      expect(transformed.statusCode, 200);
      expect(transformed.message, 'OK');
    });
  });
}

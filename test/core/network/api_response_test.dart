import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';

void main() {
  group('ApiFieldError.tryParse', () {
    test('parses error using "field" key (unified format)', () {
      final raw = {
        'field': 'driverId',
        'message': 'Required',
        'code': 'VALIDATION_REQUIRED',
      };
      final error = ApiFieldError.tryParse(raw);

      expect(error, isNotNull);
      expect(error!.field, equals('driverId'));
      expect(error.message, equals('Required'));
      expect(error.code, equals('VALIDATION_REQUIRED'));
      expect(
        error.toString(),
        equals('driverId (VALIDATION_REQUIRED): Required'),
      );
    });

    test('parses error using "name" key (legacy format)', () {
      final raw = {'name': 'driverId', 'message': 'Required'};
      final error = ApiFieldError.tryParse(raw);

      expect(error, isNotNull);
      expect(error!.field, equals('driverId'));
      expect(error.message, equals('Required'));
      expect(error.code, isNull);
      expect(error.toString(), equals('driverId: Required'));
    });

    test('prefers "field" over "name" when both are present', () {
      final raw = {
        'field': 'preferredField',
        'name': 'legacyField',
        'message': 'Invalid format',
      };
      final error = ApiFieldError.tryParse(raw);

      expect(error, isNotNull);
      expect(error!.field, equals('preferredField'));
      expect(error.message, equals('Invalid format'));
    });

    test('returns null when neither "field" nor "name" is a string', () {
      expect(ApiFieldError.tryParse({'message': 'Required'}), isNull);
      expect(
        ApiFieldError.tryParse({'field': 123, 'message': 'Required'}),
        isNull,
      );
      expect(ApiFieldError.tryParse('invalid'), isNull);
      expect(ApiFieldError.tryParse(null), isNull);
    });

    test('returns null when message is missing or not a string', () {
      expect(ApiFieldError.tryParse({'field': 'username'}), isNull);
      expect(
        ApiFieldError.tryParse({'field': 'username', 'message': 400}),
        isNull,
      );
    });
  });

  group('ApiResponse.fromBody with errors envelope', () {
    test('parses unified errors array with field and name', () {
      final body = {
        'success': false,
        'message': 'Validation failed',
        'errors': [
          {'field': 'email', 'message': 'Invalid email address'},
          {'name': 'password', 'message': 'Too short'},
        ],
        'requestId': 'req-12345',
      };

      final response = ApiResponse.fromBody<dynamic>(
        statusCode: 400,
        rawBody: body,
      );

      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Validation failed'));
      expect(response.requestId, equals('req-12345'));
      expect(response.errors.length, equals(2));
      expect(response.errors[0].field, equals('email'));
      expect(response.errors[0].message, equals('Invalid email address'));
      expect(response.errors[1].field, equals('password'));
      expect(response.errors[1].message, equals('Too short'));
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/interceptors/request_logger.dart';

void main() {
  group('RequestLogger Redaction Tests', () {
    late RequestLogger logger;

    setUp(() {
      logger = RequestLogger();
    });

    test('onError: response data with sensitive PII is redacted while coordinates pass through', () {
      final sensitiveErrorBody = {
        'error': 'validation_failed',
        'latitude': 32.7767,
        'longitude': -96.7970,
        'email': 'driver@fleet.com',
        'message': 'Location out of geofence',
      };

      final redacted = logger.redactSensitiveData(sensitiveErrorBody) as Map;
      expect(redacted['latitude'], 32.7767,
          reason: 'latitude is telemetry data and must not be redacted in logs');
      expect(redacted['longitude'], -96.7970,
          reason: 'longitude is telemetry data and must not be redacted in logs');
      expect(redacted['email'], '[REDACTED]',
          reason: 'email in error response body must be redacted');
      expect(redacted['error'], 'validation_failed',
          reason: 'non-sensitive field must pass through');
      expect(redacted['message'], 'Location out of geofence',
          reason: 'non-sensitive message field must pass through');
    });

    test('onError: redactSensitiveData handles Map response data (simulates error body redaction)', () {
      final errorResponseBody = {
        'latitude': 32.7767,
        'longitude': -96.7970,
        'email': 'driver@fleet.com',
        'error': 'validation_failed',
      };

      final redacted = logger.redactSensitiveData(errorResponseBody) as Map;
      expect(redacted['latitude'], 32.7767);
      expect(redacted['longitude'], -96.7970);
      expect(redacted['email'], '[REDACTED]');
      expect(redacted['error'], 'validation_failed',
          reason: 'non-sensitive field must pass through');
    });

    test('URL path is logged verbatim — sensitive query params are a known gap', () {
      // توثيق الفجوة المعروفة: الـ URI يُطبع كاملاً في onRequest بلا تنقيح.
      // إذا احتوت query params على locationText أو manualLocation يُسجَّل
      // ذلك كما هو. يجب تجنّب إرسال بيانات حساسة في query params.
      // هذا الاختبار يوثّق السلوك الحالي ولا يُعتبر إصلاحاً.
      final sensitiveUri = Uri.parse(
        'https://snsoft.cloud/api/eld/hardware/status?locationText=Dallas%2C+TX&driverId=101',
      );
      // التحقق: redactSensitiveData لا تعالج URI strings — فقط Maps وLists
      final result = logger.redactSensitiveData(sensitiveUri.toString());
      // النتيجة: String تُعاد كما هي (ليست Map)
      expect(result, isA<String>(),
          reason: 'URI strings are returned as-is; query param redaction is a known gap');
    });

    test('logger does not crash on complex nested maps', () {
      final options = RequestOptions(
        path: '/session',
        data: {
          'email': 'test@test.com',
          'password': 'TEST_PASSWORD_123',
          'nested': {'token': 'TEST_TOKEN_ABC', 'normal': 'value'},
          'list': [
            {'jsessionid': 'TEST_JSESSIONID_XYZ'},
          ],
        },
        headers: {
          'Cookie': 'JSESSIONID=TEST_JSESSIONID_XYZ',
          'Authorization': 'Bearer TEST_TOKEN_ABC',
        },
      );

      final handler = RequestInterceptorHandler();
      expect(() => logger.onRequest(options, handler), returnsNormally);
    });

    test('redacts authentication secrets and tokens', () {
      final data = {
        'password': 'secretPassword123',
        'token': 'jwt.token.here',
        'access_token': 'access123',
        'refresh_token': 'refresh456',
        'pin': '1234',
        'secret': 'topSecretKey',
      };

      final redacted = logger.redactSensitiveData(data) as Map;
      expect(redacted['password'], '[REDACTED]');
      expect(redacted['token'], '[REDACTED]');
      expect(redacted['access_token'], '[REDACTED]');
      expect(redacted['refresh_token'], '[REDACTED]');
      expect(redacted['pin'], '[REDACTED]');
      expect(redacted['secret'], '[REDACTED]');
    });

    test('redacts PII: email, phone, SSN, driver license', () {
      final data = {
        'email': 'driver@carrier.com',
        'phone': '+15551234567',
        'phoneNumber': '+15559876543',
        'ssn': '123-45-6789',
        'licenseNumber': 'TX987654321',
        'driverLicense': 'DL12345',
        'driverName': 'John Doe', // non-sensitive display name
      };

      final redacted = logger.redactSensitiveData(data) as Map;
      expect(redacted['email'], '[REDACTED]');
      expect(redacted['phone'], '[REDACTED]');
      expect(redacted['phoneNumber'], '[REDACTED]');
      expect(redacted['ssn'], '[REDACTED]');
      expect(redacted['licenseNumber'], '[REDACTED]');
      expect(redacted['driverLicense'], '[REDACTED]');
      expect(redacted['driverName'], 'John Doe');
    });

    test('redacts signature image bytes and drafts', () {
      final data = {
        'signatureImage': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...',
        'signatureDraft': 'base64_draft_data_string',
        'signatureData': 'signature_points_data',
        'signatureCertificateId': 'cert-uuid-1234',
        'status': 'CERTIFIED', // non-sensitive
      };

      final redacted = logger.redactSensitiveData(data) as Map;
      expect(redacted['signatureImage'], '[REDACTED]');
      expect(redacted['signatureDraft'], '[REDACTED]');
      expect(redacted['signatureData'], '[REDACTED]');
      expect(redacted['signatureCertificateId'], '[REDACTED]');
      expect(redacted['status'], 'CERTIFIED');
    });

    test('preserves telemetry coordinates, latitude, longitude, and manualLocation', () {
      final data = {
        'latitude': 32.7767,
        'longitude': -96.7970,
        'lat': 32.7767,
        'lng': -96.7970,
        'coordinates': [32.7767, -96.7970],
        'manualLocation': 'Dallas, TX',
        'locationText': 'Dallas, TX',
        'status': 'ON_DUTY',
      };

      final redacted = logger.redactSensitiveData(data) as Map;
      expect(redacted['latitude'], 32.7767);
      expect(redacted['longitude'], -96.7970);
      expect(redacted['lat'], 32.7767);
      expect(redacted['lng'], -96.7970);
      expect(redacted['manualLocation'], 'Dallas, TX');
      expect(redacted['locationText'], 'Dallas, TX');
      expect(redacted['status'], 'ON_DUTY');
    });

    test('recursively redacts nested maps and lists', () {
      final data = {
        'carrier': {'name': 'Eagle Fleet', 'email': 'fleet@carrier.com'},
        'events': [
          {'status': 'DRIVING', 'latitude': 33.123},
          {'status': 'OFF_DUTY', 'signatureImage': 'img_bytes'},
        ],
      };

      final redacted = logger.redactSensitiveData(data) as Map;
      expect((redacted['carrier'] as Map)['name'], 'Eagle Fleet');
      expect((redacted['carrier'] as Map)['email'], '[REDACTED]');

      final events = redacted['events'] as List;
      expect((events[0] as Map)['status'], 'DRIVING');
      expect((events[0] as Map)['latitude'], 33.123);
      expect((events[1] as Map)['status'], 'OFF_DUTY');
      expect((events[1] as Map)['signatureImage'], '[REDACTED]');
    });
  });

  group('RequestLogger URI Redaction', () {
    late RequestLogger logger;

    setUp(() {
      logger = RequestLogger();
    });

    test('URI with auth or token query params has values redacted', () {
      final uri = Uri.parse(
        'https://snsoft.cloud/api/eld/auth?token=secret123&apiKey=key456',
      );
      final redacted = logger.redactUri(uri);
      expect(
        redacted.contains('token=[REDACTED]') ||
            redacted.contains('token=%5BREDACTED%5D'),
        isTrue,
        reason: 'token value should be redacted in URI query params',
      );
      expect(
        redacted.contains('apiKey=[REDACTED]') ||
            redacted.contains('apiKey=%5BREDACTED%5D'),
        isTrue,
        reason: 'apiKey value should be redacted in URI query params',
      );
    });

    test('URI with driverId, latitude, and longitude preserves telemetry query params', () {
      final uri = Uri.parse(
        'https://snsoft.cloud/api/eld/events?driverId=101&latitude=32.77&longitude=-96.79',
      );
      final redacted = logger.redactUri(uri);
      expect(redacted, contains('driverId=101'));
      expect(redacted, contains('latitude=32.77'));
      expect(redacted, contains('longitude=-96.79'));
    });

    test('URI with driverId and sortBy does not redact non-sensitive keys', () {
      final uri = Uri.parse(
        'https://snsoft.cloud/api/eld/logs?driverId=101&sortBy=id',
      );
      final redacted = logger.redactUri(uri);
      expect(redacted, contains('driverId=101'));
      expect(redacted, contains('sortBy=id'));
    });

    test('URI with no query params is returned unchanged', () {
      final uri = Uri.parse('https://snsoft.cloud/api/eld/daily-logs/7');
      final redacted = logger.redactUri(uri);
      expect(redacted, 'https://snsoft.cloud/api/eld/daily-logs/7');
    });

    test('URI with password query param is redacted', () {
      final uri = Uri.parse(
        'https://snsoft.cloud/api/auth?username=user1&password=secret123',
      );
      final redacted = logger.redactUri(uri);
      expect(redacted.contains('secret123'), isFalse);
      expect(
        redacted.contains('password=[REDACTED]') ||
            redacted.contains('password=%5BREDACTED%5D'),
        isTrue,
      );
      expect(redacted.contains('username=user1'), isTrue);
    });

    test(
      'onRequest does not crash with a URI containing sensitive query params',
      () {
        final options = RequestOptions(
          path:
              'https://snsoft.cloud/api/events?locationText=Dallas%2C+TX&latitude=32.77',
        );
        final handler = RequestInterceptorHandler();
        expect(() => logger.onRequest(options, handler), returnsNormally);
      },
    );
  });
}

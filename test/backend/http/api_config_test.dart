import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/api_config.dart';

void main() {
  group('ApiConfig — construction', () {
    test('has sensible defaults', () {
      const config = ApiConfig(baseUrl: 'https://api.example.com');
      expect(config.connectTimeout, const Duration(seconds: 12));
      expect(config.receiveTimeout, const Duration(seconds: 30));
      expect(config.sendTimeout, const Duration(seconds: 30));
      expect(config.defaultHeaders, {'Accept': 'application/json'});
    });

    test('isValid returns false for empty URL', () {
      const config = ApiConfig(baseUrl: '');
      expect(config.isValid, isFalse);
    });

    test('isValid returns true for valid URL', () {
      const config = ApiConfig(baseUrl: 'https://api.example.com');
      expect(config.isValid, isTrue);
    });
  });

  group('ApiConfig — normalized', () {
    test('adds https scheme when missing', () {
      const config = ApiConfig(baseUrl: 'api.example.com');
      expect(config.normalized().baseUrl, 'https://api.example.com');
    });

    test('removes trailing slash', () {
      const config = ApiConfig(baseUrl: 'https://api.example.com/');
      expect(config.normalized().baseUrl, 'https://api.example.com');
    });

    test('removes multiple trailing slashes', () {
      const config = ApiConfig(baseUrl: 'https://api.example.com///');
      expect(config.normalized().baseUrl, 'https://api.example.com');
    });

    test('preserves explicit http scheme', () {
      const config = ApiConfig(baseUrl: 'http://localhost:8080');
      expect(config.normalized().baseUrl, 'http://localhost:8080');
    });

    test('trims whitespace', () {
      const config = ApiConfig(baseUrl: '  https://api.example.com  ');
      expect(config.normalized().baseUrl, 'https://api.example.com');
    });

    test('keeps /api path', () {
      const config = ApiConfig(baseUrl: 'https://api.example.com/api/');
      expect(config.normalized().baseUrl, 'https://api.example.com/api');
    });
  });

  group('ApiConfig — equality', () {
    test('equal when baseUrl and timeouts match', () {
      const a = ApiConfig(baseUrl: 'https://x.com');
      const b = ApiConfig(baseUrl: 'https://x.com');
      expect(a, equals(b));
    });

    test('not equal when baseUrl differs', () {
      const a = ApiConfig(baseUrl: 'https://x.com');
      const b = ApiConfig(baseUrl: 'https://y.com');
      expect(a, isNot(equals(b)));
    });
  });
}

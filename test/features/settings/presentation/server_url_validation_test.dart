import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/settings/presentation/server_url_validation.dart';

void main() {
  group('P1 — isHttpsServerUrl', () {
    test('accepts https origins (with port/path and surrounding spaces)', () {
      expect(isHttpsServerUrl('https://snsoft.cloud'), isTrue);
      expect(isHttpsServerUrl(' https://eld.example.com:8443/api '), isTrue);
      expect(isHttpsServerUrl('HTTPS://ELD.EXAMPLE.COM'), isTrue);
    });

    test('rejects plaintext http — credentials must not travel in clear', () {
      expect(isHttpsServerUrl('http://snsoft.cloud'), isFalse);
      expect(
        isHttpsServerUrl('http://192.168.1.10:8080'),
        isFalse,
        reason: 'قبول http يعني اعتماداً وموقعاً صريحين فوق قناة مكشوفة',
      );
    });

    test('rejects other schemes and malformed values', () {
      expect(isHttpsServerUrl('ftp://files.example.com'), isFalse);
      expect(isHttpsServerUrl('javascript:alert(1)'), isFalse);
      expect(isHttpsServerUrl('https://'), isFalse);
      expect(isHttpsServerUrl('https:///nohost'), isFalse);
      expect(isHttpsServerUrl('snsoft.cloud'), isFalse);
      expect(isHttpsServerUrl(''), isFalse);
      expect(isHttpsServerUrl('   '), isFalse);
    });
  });
}

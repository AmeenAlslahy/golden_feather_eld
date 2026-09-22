import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/config/server_config.dart';

void main() {
  group('ServerConfig', () {
    test('normalizeUrl trims and adds https scheme', () {
      expect(ServerConfig.normalizeUrl(' example.com '), 'https://example.com');
      expect(ServerConfig.normalizeUrl('http://example.com/'), 'http://example.com');
      expect(ServerConfig.normalizeUrl('https://snsoft.cloud/api//'), 'https://snsoft.cloud/api');
    });

    test('BackendType.fromWire', () {
      expect(BackendType.fromWire('eld'), BackendType.eld);
      expect(BackendType.fromWire('traccar'), BackendType.traccar);
      expect(BackendType.fromWire('invalid'), BackendType.eld);
      expect(BackendType.fromWire(null), BackendType.eld);
    });

    test('unverified factory', () {
      final config = ServerConfig.unverified(baseUrl: 'example.com');
      expect(config.baseUrl, 'https://example.com');
      expect(config.backendType, BackendType.eld);
      expect(config.isVerified, false);
      expect(config.isUsable, false);
    });

    test('verified factory', () {
      final config = ServerConfig.verified(baseUrl: 'example.com', backendType: BackendType.traccar);
      expect(config.baseUrl, 'https://example.com');
      expect(config.backendType, BackendType.traccar);
      expect(config.isVerified, true);
      expect(config.isUsable, true);
    });
  });
}

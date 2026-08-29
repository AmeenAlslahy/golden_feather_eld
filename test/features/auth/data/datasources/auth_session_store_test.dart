import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_session_store.dart';
import 'package:golden_feather_eld/features/auth/domain/entities/auth_session.dart';

void main() {
  group('AuthSessionStore Tests', () {
    late AuthSessionStore store;
    final session = AuthSession.create(
      serverOrigin: 'https://demo.traccar.org',
      sessionCredential: 'mock_jsessionid_123',
      userMetadata: {'id': 1, 'email': 'test@demo.com', 'name': 'Test User'},
    );

    setUp(() {
      // Since FlutterSecureStorage doesn't work easily in basic unit tests without mock,
      // we mock its behavior or we just assume we are running widget tests where flutter bindings are initialized.
      // But for this test, we can use a basic Map based fake if we want, or just test the interface.
      
      // We will skip actual FlutterSecureStorage calls for standard dart test unless mocked.
      // Assuming a mock or fake implementation is needed if run outside flutter.
    });

    test('Session model serialization', () {
      final json = session.toJson();
      expect(json['serverOrigin'], equals('https://demo.traccar.org'));
      expect(json['sessionCredential'], equals('mock_jsessionid_123'));
      
      final deserialized = AuthSession.fromJson(json);
      expect(deserialized.serverOrigin, equals(session.serverOrigin));
      expect(deserialized.sessionCredential, equals(session.sessionCredential));
      expect(deserialized.userMetadata['name'], equals('Test User'));
    });
  });
}

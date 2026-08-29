import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/auth/domain/entities/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('should not expose JSESSIONID in toString for security', () {
      final session = AuthSession.create(
        serverOrigin: 'https://test.invalid',
        sessionCredential: 'secret_cookie_value',
        userMetadata: {'id': 1},
      );

      final stringRepresentation = session.toString();
      
      expect(stringRepresentation.contains('secret_cookie_value'), isFalse, reason: 'Session credential must be redacted in toString');
      expect(stringRepresentation.contains('[REDACTED]'), isTrue);
      expect(stringRepresentation.contains('https://test.invalid'), isTrue);
    });

    test('should correctly identify if it belongs to an origin', () {
      final session = AuthSession.create(
        serverOrigin: 'https://test.invalid:5055',
        sessionCredential: 'token',
        userMetadata: {},
      );

      expect(session.belongsTo('https://test.invalid:5055'), isTrue);
      expect(session.belongsTo('https://TEST.invalid:5055'), isTrue, reason: 'Origin comparison should be case-insensitive');
      expect(session.belongsTo('https://test.invalid'), isFalse, reason: 'Different port implies different origin');
      expect(session.belongsTo('http://test.invalid:5055'), isFalse, reason: 'Different scheme implies different origin');
    });
  });
}

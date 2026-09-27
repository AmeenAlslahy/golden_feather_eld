import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/data/models/user_model.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/data/models/auth_session_dto.dart';

void main() {
  group('AuthLocalDataSource Tests', () {
    final userModel = UserModel(
      id: '1',
      username: 'test@demo.com',
      email: 'test@demo.com',
      fullName: 'Test User',
      role: UserRole.fieldWorker,
      createdAt: DateTime.now(),
    );

    final sessionDto = AuthSessionDto.create(
      serverOrigin: 'https://demo.traccar.org',
      sessionCredential: 'mock_jsessionid_123',
      userModel: userModel,
    );

    setUp(() {});

    test('Session model serialization', () {
      final json = sessionDto.toJson();
      expect(json['serverOrigin'], equals('https://demo.traccar.org'));
      expect(json['sessionCredential'], equals('mock_jsessionid_123'));

      final deserialized = AuthSessionDto.fromJson(json);
      expect(deserialized.serverOrigin, equals(sessionDto.serverOrigin));
      expect(deserialized.sessionCredential, equals(sessionDto.sessionCredential));
      expect(deserialized.userModel.fullName, equals('Test User'));
    });
  });
}

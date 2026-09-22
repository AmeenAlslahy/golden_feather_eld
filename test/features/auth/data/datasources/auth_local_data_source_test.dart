import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/data/models/auth_session_dto.dart';
import 'package:golden_feather_eld/features/auth/data/models/user_model.dart';

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
      expect(deserialized.userModel.id, equals('1'));
    });

    test('UserModel handles integer id from Traccar API', () {
      final apiJson = {
        'id': 106,
        'name': 'Driver Test',
        'email': 'driver@test.com',
        'administrator': false,
        'disabled': false,
      };
      final user = UserModel.fromJson(apiJson);
      expect(user.id, equals('106'));
      expect(user.fullName, equals('Driver Test'));
      expect(user.email, equals('driver@test.com'));
      expect(user.isActive, isTrue);
    });

    test('UserModel handles string id from storage JSON', () {
      final storageJson = {
        'id': '106',
        'name': 'Driver Test',
        'email': 'driver@test.com',
        'role': 'field_worker',
        'isActive': true,
      };
      final user = UserModel.fromJson(storageJson);
      expect(user.id, equals('106'));
      expect(user.isActive, isTrue);
    });
  });
}

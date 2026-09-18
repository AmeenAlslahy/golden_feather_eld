import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_account_backend.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

void main() {
  late MockAccountBackend backend;

  setUp(() {
    backend = MockAccountBackend();
  });

  group('MockAccountBackend.getProfile', () {
    test('returns fixture with overridden id', () async {
      final result = await backend.getProfile(const DriverId(202));

      result.tap(onSuccess: (data) {
        expect(data['id'], 202);
        expect(data['name'], 'سعد بن محمد العتيبي');
      });
    });
  });

  group('MockAccountBackend.updateProfile', () {
    test('merges update into current profile', () async {
      final result = await backend.updateProfile(
        driverId: const DriverId(101),
        update: {'phone': '+111111'},
      );

      result.tap(onSuccess: (data) {
        expect(data['phone'], '+111111');
        // Original field preserved
        expect(data['name'], 'سعد بن محمد العتيبي');
      });
    });

    test('subsequent getProfile reflects update', () async {
      await backend.updateProfile(
        driverId: const DriverId(101),
        update: {'phone': '+999999'},
      );

      final result = await backend.getProfile(const DriverId(101));

      result.tap(onSuccess: (data) {
        expect(data['phone'], '+999999');
      });
    });

    test('updates are isolated per driverId', () async {
      await backend.updateProfile(
        driverId: const DriverId(101),
        update: {'phone': '+101'},
      );
      await backend.updateProfile(
        driverId: const DriverId(202),
        update: {'phone': '+202'},
      );

      final first = await backend.getProfile(const DriverId(101));
      final second = await backend.getProfile(const DriverId(202));

      first.tap(onSuccess: (d) => expect(d['phone'], '+101'));
      second.tap(onSuccess: (d) => expect(d['phone'], '+202'));
    });
  });

  group('MockAccountBackend.getMyAccount', () {
    test('returns my account fixture', () async {
      final result = await backend.getMyAccount();

      result.tap(onSuccess: (data) {
        expect(data['name'], 'Naseem Hassan Ali Adam');
        expect(data['editableFields'], contains('language'));
      });
    });
  });

  group('MockAccountBackend.updatePreferences', () {
    test('returns updated preferences', () async {
      final result = await backend.updatePreferences(
        language: 'ar',
        odometerUnit: 'km',
      );

      result.tap(onSuccess: (data) {
        expect(data['language'], 'ar');
        expect(data['odometer'], 'km');
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_account_backend.dart';

void main() {
  late MockAccountBackend backend;

  setUp(() {
    backend = MockAccountBackend();
  });

  group('MockAccountBackend.getMyAccount', () {
    test('returns my account fixture', () async {
      final result = await backend.getMyAccount();

      result.tap(onSuccess: (data) {
        expect(data.email, 'driver@example.com');
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
        expect(data.language, 'ar');
        expect(data.odometer, 'km');
      });
    });
  });
}

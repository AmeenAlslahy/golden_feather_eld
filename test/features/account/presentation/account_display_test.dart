import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/account/driver_account.dart';
import 'package:golden_feather_eld/features/account/presentation/utils/account_display.dart';

void main() {
  group('languageDisplayNameForCode', () {
    test('maps ar/es/en and falls back to English', () {
      expect(languageDisplayNameForCode('ar'), 'Arabic');
      expect(languageDisplayNameForCode('es'), 'Spanish');
      expect(languageDisplayNameForCode('en'), 'English');
      expect(languageDisplayNameForCode('fr'), 'English');
    });
  });

  group('languageCodeForDisplayName', () {
    test('maps known display names (case-insensitive) to codes', () {
      expect(languageCodeForDisplayName('Arabic'), 'ar');
      expect(languageCodeForDisplayName('arabic'), 'ar');
      expect(languageCodeForDisplayName('العربية'), 'ar');
      expect(languageCodeForDisplayName('Spanish'), 'es');
      expect(languageCodeForDisplayName('español'), 'es');
      expect(languageCodeForDisplayName('English'), 'en');
    });

    test('unknown display names return null instead of a wrong code', () {
      expect(languageCodeForDisplayName('French'), isNull);
      expect(languageCodeForDisplayName(''), isNull);
    });
  });

  group('licenseDisplayText', () {
    test('prefers the formatted value when it contains a comma', () {
      const license = LicenseInfo(
        state: 'TX',
        number: 'DL-999',
        formatted: 'TX, DL-999',
      );
      expect(licenseDisplayText(license), 'TX, DL-999');
    });

    test('combines state and number when formatted is not combined', () {
      const license = LicenseInfo(
        state: 'TX',
        number: 'DL-999',
        formatted: 'DL-999',
      );
      expect(licenseDisplayText(license), 'TX, DL-999');
    });
  });
}

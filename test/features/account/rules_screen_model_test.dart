import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';

void main() {
  RulesScreenModel makeModel(Map<String, dynamic> fixedSettings) {
    return RulesScreenModel(
      ruleSource: 'USA',
      cycleRule: '70/8',
      cargoType: 'Property',
      restart: '34h',
      restBreak: '30m',
      sixteenHourException: false,
      options: const {},
      editableFields: const {},
      readOnlyFields: const {},
      fixedSettings: fixedSettings,
      notice: '',
      limits: HosConfiguration.usa70_8(),
    );
  }

  group('RulesScreenModel._isSettingAllowed', () {
    test('accepts boolean true and rejects boolean false', () {
      final modelTrue = makeModel({'personalConveyance': true, 'yardMoves': false});
      expect(modelTrue.isPersonalConveyanceAllowed, isTrue);
      expect(modelTrue.isYardMoveAllowed, isFalse);
    });

    test('accepts various affirmative string values: allowed, true, yes, 1, enabled, on, permitted', () {
      for (final affirmative in ['allowed', 'Allowed', 'TRUE', 'yes', '1', 'enabled', 'on', 'permitted']) {
        final model = makeModel({'personalConveyance': affirmative, 'yardMoves': affirmative});
        expect(model.isPersonalConveyanceAllowed, isTrue, reason: 'Failed for $affirmative');
        expect(model.isYardMoveAllowed, isTrue, reason: 'Failed for $affirmative');
      }
    });

    test('rejects negative string values: forbidden, false, no, 0, disabled, off', () {
      for (final negative in ['forbidden', 'Forbidden', 'FALSE', 'no', '0', 'disabled', 'off']) {
        final model = makeModel({'personalConveyance': negative, 'yardMoves': negative});
        expect(model.isPersonalConveyanceAllowed, isFalse, reason: 'Should reject $negative');
        expect(model.isYardMoveAllowed, isFalse, reason: 'Should reject $negative');
      }
    });

    test('defaults to false for missing keys or unknown values', () {
      final model = makeModel({'unrelated': 'value', 'personalConveyance': 'unknown_token'});
      expect(model.isPersonalConveyanceAllowed, isFalse);
      expect(model.isYardMoveAllowed, isFalse);
    });
  });

  group('RulesScreenModel.tryIsSettingAllowed', () {
    test('returns true/false for recognized values and null for unknown', () {
      final model = makeModel({
        'personalConveyance': 'permitted',
        'yardMoves': false,
      });
      expect(model.tryIsSettingAllowed(const ['personalConveyance']), isTrue);
      expect(model.tryIsSettingAllowed(const ['yardMoves']), isFalse);
      expect(model.tryIsSettingAllowed(const ['unlimitedTrailers']), isNull);
      expect(model.tryIsSettingAllowed(const ['personalConveyance', 'personalConveyanceEnabled']), isTrue);
    });

    test('unrecognized token stays unknown instead of false', () {
      final model = makeModel({'personalConveyance': 'custom_value'});
      expect(model.tryIsSettingAllowed(const ['personalConveyance']), isNull);
      expect(model.isPersonalConveyanceAllowed, isFalse);
    });
  });

  group('RulesScreenModel.firstSettingDisplayText', () {
    test('returns the first raw server text, including unrecognized tokens', () {
      final model = makeModel({'personalConveyance': 'custom_value'});
      expect(model.firstSettingDisplayText(const ['personalConveyance']), 'custom_value');
      expect(model.firstSettingDisplayText(const ['missing']), isNull);
    });
  });
}

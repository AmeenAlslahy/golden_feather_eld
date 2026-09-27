import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/rules_screen_options.dart';

void main() {
  test('rules options come from the server and do not add Mexico Only', () {
    final options = readRulesOptions({
      'availableCycleRules': ['USA 70 hour / 8 day'],
      'availableCargoTypes': ['Property'],
    });

    expect(options['cycleRule'], ['USA 70 hour / 8 day']);
    expect(options['cargoType'], ['Property']);
    expect(options.values.expand((items) => items), isNot(contains('Mexico Only')));
  });

  test('a missing options object does not invent a federal rule', () {
    expect(readRulesOptions(null), isEmpty);
    expect(readRulesOptions({'availableCycleRules': []}), isEmpty);
  });
}

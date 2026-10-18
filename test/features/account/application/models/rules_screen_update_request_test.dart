import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_update_request.dart';

void main() {
  group('RulesScreenUpdateRequest', () {
    test('toJson generates correct map', () {
      const req = RulesScreenUpdateRequest(
        cycleRule: 'Rule A',
        cargoType: 'Type B',
        restart: 'Restart C',
        restBreak: 'Break D',
        sixteenHourException: true,
      );

      final json = req.toJson();
      expect(json, {
        'cycleRule': 'Rule A',
        'cargoType': 'Type B',
        'restart': 'Restart C',
        'restBreak': 'Break D',
        'sixteenHourException': true,
      });
    });
  });
}

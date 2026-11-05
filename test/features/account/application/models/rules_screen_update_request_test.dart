import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_update_request.dart';

void main() {
  group('RulesScreenUpdateRequest', () {
    test('toJson generates correct map with legacy and canonical OAS 3.0 fields', () {
      const req = RulesScreenUpdateRequest(
        cycleRule: 'Rule A',
        cargoType: 'Type B',
        restart: 'Restart C',
        restBreak: 'Break D',
        sixteenHourException: true,
      );

      final json = req.toJson();
      expect(json['cycleRule'], 'Rule A');
      expect(json['cargoType'], 'Type B');
      expect(json['restart'], 'Restart C');
      expect(json['restBreak'], 'Break D');
      expect(json['sixteenHourException'], true);

      // OAS 3.0 canonical fields
      expect(json['ruleSetId'], isNotNull);
      expect(json['restartType'], isNotNull);
      expect(json['breakPolicy'], isNotNull);
      expect(json['sixteenHourExceptionEnabled'], true);
      expect(json['shortHaulEnabled'], false);
      expect(json['personalConveyanceAllowed'], true);
      expect(json['yardMovesAllowed'], true);
      expect(json['reason'], isNotEmpty);
    });

    test('toJson normalizes canonical rule identifiers', () {
      const req = RulesScreenUpdateRequest(
        cycleRule: 'USA 70/8',
        cargoType: 'PROPERTY',
        restart: '34h',
        restBreak: '30m',
        sixteenHourException: false,
      );

      final json = req.toJson();
      expect(json['ruleSetId'], 'USA_70_8');
      expect(json['restartType'], '34_HOURS');
      expect(json['breakPolicy'], 'REQUIRED_30_MIN');
      expect(json['sixteenHourExceptionEnabled'], false);
    });
  });
}

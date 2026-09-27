import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';

void main() {
  group('DutyStatusCode.countsAsOnDuty', () {
    test('personal conveyance is off-duty per FMCSA', () {
      // Personal conveyance لا يُحتسب ضمن نافذة 14 ساعة ولا حد 11 ساعة
      // قيادة (الساعة لا تتوقف، لكنه لا يُتراكم).
      expect(DutyStatusCode.personalConveyance.countsAsOnDuty, isFalse);
    });

    test('driving / on-duty / yard move count as on-duty', () {
      expect(DutyStatusCode.driving.countsAsOnDuty, isTrue);
      expect(DutyStatusCode.onDutyNotDriving.countsAsOnDuty, isTrue);
      expect(DutyStatusCode.yardMove.countsAsOnDuty, isTrue);
    });

    test('off duty and sleeper do not count', () {
      expect(DutyStatusCode.offDuty.countsAsOnDuty, isFalse);
      expect(DutyStatusCode.sleeperBerth.countsAsOnDuty, isFalse);
    });
  });

  group('DutyStatusCode.fromWire', () {
    test('parses known wire values case-insensitively', () {
      expect(DutyStatusCode.fromWire('DRIVING'), DutyStatusCode.driving);
      expect(DutyStatusCode.fromWire('on_duty'), DutyStatusCode.onDutyNotDriving);
      expect(DutyStatusCode.fromWire('PERSONAL_CONVEYANCE'),
          DutyStatusCode.personalConveyance);
    });

    test('unknown values fall back to offDuty (logged upstream)', () {
      expect(DutyStatusCode.fromWire('WHATEVER'), DutyStatusCode.offDuty);
      expect(DutyStatusCode.fromWire(null), DutyStatusCode.offDuty);
    });
  });
}

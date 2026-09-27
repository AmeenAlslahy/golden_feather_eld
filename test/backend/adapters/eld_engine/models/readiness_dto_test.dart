import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/readiness_dto.dart';

void main() {
  test('pending carrier edits are read from readiness without invented ids', () {
    final dto = ReadinessDto.fromJson({
      'dailyLogId': 12,
      'driverId': 1,
      'driverName': 'A',
      'logDate': '2026-09-24',
      'readinessStatus': 'NOT_READY',
      'missingRequirements': ['carrier_edit'],
      'legalStatement': 'stmt',
      'availableActions': ['respond'],
      'carrierProposedEditsPending': true,
      'pendingCarrierEdits': [
        {'id': 'ed-1', 'proposedStatus': 'OFF_DUTY', 'carrierReason': 'Fix'},
        {'id': '  '},
      ],
    });

    expect(dto.carrierProposedEditsPending, isTrue);
    expect(dto.pendingCarrierEdits, hasLength(1));
    expect(dto.pendingCarrierEdits.single.id, 'ed-1');
    expect(dto.pendingCarrierEdits.single.proposedStatus, 'OFF_DUTY');
  });
}

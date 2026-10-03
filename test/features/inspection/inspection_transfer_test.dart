import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/inspection/data/mappers/inspection_mappers.dart';
import 'package:golden_feather_eld/features/inspection/domain/inspection_transfer.dart';

void main() {
  test('comment is refused outside 4 to 60 characters', () {
    expect(isValidInspectionComment('abc'), isFalse);
    expect(isValidInspectionComment('a' * 61), isFalse);
    expect(isValidInspectionComment('road'), isTrue);
    expect(isValidInspectionComment('  road  '), isTrue);
  });


  test('a failed transfer status is not shown as accepted', () {
    final outcome = readTransferOutcome({
      'status': 'FAILED',
      'message': 'Comment length is invalid',
    });
    expect(outcome.accepted, isFalse);
    expect(outcome.text, 'Comment length is invalid');
  });

  test('packet stays incomplete when a mandatory item is missing', () {
    final view = parseInformationPacket({
      'complete': true,
      'title': 'Packet',
      'missingItems': ['blank logs'],
      'items': [
        {'title': 'User manual', 'available': false, 'mandatory': true},
        {'title': 'Malfunction instructions', 'available': true, 'mandatory': true},
      ],
    });
    expect(view.complete, isFalse);
    expect(view.missing, contains('blank logs'));
    expect(view.missing, contains('User manual'));
  });

  test('an empty packet is not marked complete', () {
    final view = parseInformationPacket(const {});
    expect(view.complete, isFalse);
    expect(view.statusText, 'Incomplete');
  });
}

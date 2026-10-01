import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/features/inspection/domain/entities/inspection_data.dart';
import 'package:golden_feather_eld/features/inspection/domain/inspection_transfer.dart';

void main() {
  test('comment is refused outside 4 to 60 characters', () {
    final loc = lookupAppLocalizations(const Locale('en'));
    expect(inspectionCommentError('abc', loc: loc), isNotNull);
    expect(inspectionCommentError('a' * 61, loc: loc), isNotNull);
    expect(inspectionCommentError('road', loc: loc), isNull);
    expect(inspectionCommentError('  road  ', loc: loc), isNull);
  });

  test('every roadside method uses the live transfer type', () {
    expect(transferTypeFor(TransferMethod.webService), InspectionTransferType.webServices);
    expect(transferTypeFor(TransferMethod.email), InspectionTransferType.email);
    expect(transferTypeFor(TransferMethod.usb).wire, 'USB');
    expect(transferTypeFor(TransferMethod.bluetooth).wire, 'BLUETOOTH');
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

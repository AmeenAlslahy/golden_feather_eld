import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/unidentified_events_provider.dart';

void main() {
  test('server list uses statusId and does not invent a local id', () {
    final items = parseUnidentifiedList({
      'items': [
        {
          'statusId': 88,
          'status': 'DRIVING',
          'startTime': '2026-09-23T01:00:00Z',
          'endTime': '2026-09-23T02:00:00Z',
          'formattedDuration': '1h 0m',
          'locationText': 'I-5',
          'vehicleName': 'Truck 4',
          'daysPending': 3,
          'overdue': false,
        },
      ],
    });

    expect(items, hasLength(1));
    expect(items.single['statusId'], 88);
    expect(items.single['dutyStatus'], 'DRIVING');
    expect(items.single['location'], 'I-5');
  });

  test('a row without a server statusId cannot be claimed', () {
    final item = normalizeUnidentifiedItem({
      'dutyStatus': 'DRIVING',
      'startTime': '2026-09-23T01:00:00Z',
    });

    expect(item['statusId'], isNull);
  });

  test('an empty successful payload stays empty', () {
    expect(parseUnidentifiedList({'items': const []}), isEmpty);
    expect(parseUnidentifiedList(const {}), isEmpty);
  });
}

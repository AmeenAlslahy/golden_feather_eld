import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/inspection/domain/transfer_audit.dart';

void main() {
  test('transfer audit reads a wrapped server list without inventing rows', () {
    final rows = parseTransferAudit({
      'data': {
        'transfers': [
          {
            'channel': 'EMAIL',
            'recipient': 'inspector@example.com',
            'status': 'SENT',
            'transferredAt': '2026-09-23T08:15:00Z',
          },
          {'note': 'ignored because it has no audit fields'},
        ],
      },
    });

    expect(rows, isNotNull);
    expect(rows, hasLength(1));
    expect(rows!.single.channel, 'EMAIL');
    expect(rows.single.status, 'SENT');
    expect(rows.single.transferredAt, '2026-09-23T08:15:00Z');
  });

  test('SRS 8.10 — period and record count are read when the server sends them',
      () {
    final rows = parseTransferAudit({
      'transfers': [
        {
          'channel': 'EMAIL',
          'status': 'SENT',
          'transferredAt': '2026-09-23T08:15:00Z',
          'startDate': '2026-09-16',
          'endDate': '2026-09-23',
          'recordCount': 8,
        },
        {
          'channel': 'EMAIL',
          'status': 'FAILED',
          'transferredAt': '2026-09-22T08:15:00Z',
        },
      ],
    })!;
    expect(rows.first.period, '2026-09-16 – 2026-09-23');
    expect(rows.first.recordCount, '8');
    expect(rows.last.period, '');
    expect(rows.last.recordCount, '');
  });

  test('an empty transfer list is an empty read, not an error', () {
    expect(parseTransferAudit({'transfers': []}), isEmpty);
  });

  test('a body that is not a list is not treated as an empty official record', () {
    expect(parseTransferAudit({'status': 'ok'}), isNull);
  });
}

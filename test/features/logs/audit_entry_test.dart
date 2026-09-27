import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/audit_entry.dart';

void main() {
  final entry = AuditEntry(
    id: 'id-1',
    timestamp: DateTime.utc(2026, 9, 23, 10, 30),
    driverId: '42',
    oldStatus: 'ON',
    newStatus: 'D',
    reason: 'correction',
  );

  test('toMap stores the timestamp as an ISO string', () {
    final map = entry.toMap();
    expect(map['timestamp'], isA<String>());
    expect(map['timestamp'], '2026-09-23T10:30:00.000Z');
  });

  test('toMap -> fromMap round trip keeps all fields', () {
    final read = AuditEntry.fromMap(entry.toMap());
    expect(read, entry);
  });

  test('fromMap accepts a legacy int millisecond timestamp', () {
    final read = AuditEntry.fromMap(const {
      'id': 'id-2',
      'timestamp': 1000,
      'driverId': '1',
      'newStatus': 'OFF',
      'reason': 'r',
    });
    expect(read.timestamp, DateTime.fromMillisecondsSinceEpoch(1000));
  });

  test('fromMap never throws on a corrupt row', () {
    final read = AuditEntry.fromMap(const {'timestamp': 'not-a-date'});
    expect(read.id, '');
    // epoch zero — expressed timezone-independently: production parses
    // without isUtc, so a local-midnight DateTime(1970) would only match
    // on UTC machines.
    expect(read.timestamp, DateTime.fromMillisecondsSinceEpoch(0));
    expect(read.newStatus, '');
  });
}

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

  test('SRS 7.16 fields round-trip (action, entity, user, role)', () {
    final entry = AuditEntry(
      id: 'id-9',
      timestamp: DateTime.utc(2026, 9, 28, 12),
      driverId: '106',
      newStatus: '',
      reason: '',
      action: 'sign_dvir',
      entityType: 'dvir',
      entityId: 'dvir-77',
      userName: 'Naseem Adam',
      userRole: 'driver',
    );
    final read = AuditEntry.fromMap(entry.toMap());
    expect(read, entry);
    expect(read.action, 'sign_dvir');
    expect(read.entityType, 'dvir');
    expect(read.entityId, 'dvir-77');
    expect(read.userName, 'Naseem Adam');
    expect(read.userRole, 'driver');
  });

  test('legacy rows without the new fields default cleanly', () {
    final read = AuditEntry.fromMap(const {
      'id': 'legacy',
      'timestamp': '2026-09-23T10:30:00.000Z',
      'driverId': '1',
      'newStatus': 'OFF',
      'reason': 'r',
    });
    expect(read.action, '');
    expect(read.entityType, isNull);
    expect(read.entityId, isNull);
    expect(read.userName, isNull);
    expect(read.userRole, isNull);
  });
}

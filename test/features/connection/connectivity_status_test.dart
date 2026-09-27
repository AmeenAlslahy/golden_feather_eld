import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/connection/domain/connectivity_status.dart';

void main() {
  test('a missing status is not connected', () {
    final read = parseConnectivityStatus({'vehicleName': 'Truck'});

    expect(read, isNotNull);
    expect(read!.connectionStatus, isNull);
    expect(read.hasDiagnostic, isFalse);
    expect(read.hasMalfunction, isFalse);
  });

  test('diagnostics and malfunctions come only from the server lists', () {
    final read = parseConnectivityStatus({
      'connectionStatus': 'CONNECTED',
      'activeDiagnostics': ['POWER'],
      'activeMalfunctions': ['ENGINE'],
    });

    expect(read!.hasDiagnostic, isTrue);
    expect(read.hasMalfunction, isTrue);
    expect(read.diagnostics, ['POWER']);
  });

  test('only a MAC-shaped eldIdentifier is offered as a MAC', () {
    final mac = parseConnectivityStatus({
      'eldIdentifier': 'AA:BB:CC:DD:EE:FF',
    });
    final other = parseConnectivityStatus({
      'eldIdentifier': 'ELD-PRO-1001',
    });

    expect(mac!.macAddress, 'AA:BB:CC:DD:EE:FF');
    expect(other!.macAddress, isNull);
  });

  test('a non-object body is unreadable', () {
    expect(parseConnectivityStatus(['CONNECTED']), isNull);
    expect(parseConnectivityStatus({'activeDiagnostics': 'POWER'}), isNull);
  });
}

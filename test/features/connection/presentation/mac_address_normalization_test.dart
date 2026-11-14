import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/features/connection/presentation/mac_address_validation.dart';

void main() {
  group('MAC Address Normalization Tests', () {
    test('normalizes 12-character hex MAC without colons (as on PT30-U label)', () {
      expect(normalizeMacAddress('E0B488C7CAE9'), equals('E0:B4:88:C7:CA:E9'));
      expect(normalizeMacAddress('e0b488c7cae9'), equals('E0:B4:88:C7:CA:E9'));
      expect(BluetoothService.formatMacAddress('E0B488C7CAE9'), equals('E0:B4:88:C7:CA:E9'));
      expect(BluetoothService.formatMacAddress('e0b488c7cae9'), equals('E0:B4:88:C7:CA:E9'));
    });

    test('normalizes hyphen-separated MAC addresses', () {
      expect(normalizeMacAddress('E0-B4-88-C7-CA-E9'), equals('E0:B4:88:C7:CA:E9'));
      expect(BluetoothService.formatMacAddress('E0-B4-88-C7-CA-E9'), equals('E0:B4:88:C7:CA:E9'));
    });

    test('preserves already standard colon-separated MAC addresses', () {
      expect(normalizeMacAddress('E0:B4:88:C7:CA:E9'), equals('E0:B4:88:C7:CA:E9'));
      expect(BluetoothService.formatMacAddress('E0:B4:88:C7:CA:E9'), equals('E0:B4:88:C7:CA:E9'));
    });

    test('returns null for device names and non-hex strings to trigger scan resolution', () {
      expect(normalizeMacAddress('PT30'), isNull);
      expect(normalizeMacAddress('PT30-U'), isNull);
      expect(normalizeMacAddress('ELD-TRUCK-1'), isNull);
      expect(BluetoothService.formatMacAddress('PT30'), isNull);
      expect(BluetoothService.formatMacAddress('PT30-U'), isNull);
      expect(BluetoothService.formatMacAddress('ELD-TRUCK-1'), isNull);
    });
  });
}

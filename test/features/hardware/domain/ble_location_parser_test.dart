import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/hardware/domain/ble_device_catalog.dart';
import 'package:golden_feather_eld/features/hardware/domain/ble_location_parser.dart';

void main() {
  group('BleLocationFrameParser — NMEA', () {
    test('decodes RMC into latitude, longitude, m/s and bearing', () {
      final parser = BleLocationFrameParser();

      final fix = parser.parseLine(
        r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W',
      );

      expect(fix, isNotNull);
      expect(fix!.latitude, closeTo(48.1173, 0.0001));
      expect(fix.longitude, closeTo(11.5167, 0.0001));
      // 22.4 knots -> 11.52 m/s.
      expect(fix.speedMps, closeTo(11.52, 0.01));
      expect(fix.bearing, closeTo(84.4, 0.01));
      expect(fix.protocol, 'nmea-rmc');
      expect(fix.isValid, isTrue);
    });

    test('decodes GGA fix quality, altitude and HDOP-derived accuracy', () {
      final parser = BleLocationFrameParser();

      final fix = parser.parseLine(
        r'$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,',
      );

      expect(fix, isNotNull);
      expect(fix!.altitude, closeTo(545.4, 0.01));
      expect(fix.accuracy, closeTo(4.5, 0.01));
      expect(fix.protocol, 'nmea-gga');
    });

    test('rejects RMC with an invalid checksum', () {
      final parser = BleLocationFrameParser();

      final fix = parser.parseLine(
        r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*00',
      );

      expect(fix, isNull);
    });

    test('rejects a GGA sentence without a fix', () {
      final parser = BleLocationFrameParser();

      final fix = parser.parseLine(
        r'$GPGGA,123519,4807.038,N,01131.000,E,0,00,0.9,545.4,M,46.9,M,,',
      );

      expect(fix, isNull);
    });
  });

  group('BleLocationFrameParser — streaming', () {
    test('reassembles a sentence split across notifications', () {
      final parser = BleLocationFrameParser();
      final sentence =
          (r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W'
                  '\r\n')
              .codeUnits;

      final firstHalf = parser.addBytes(sentence.sublist(0, 10));
      expect(firstHalf, isEmpty);

      final secondHalf = parser.addBytes(sentence.sublist(10));
      expect(secondHalf, hasLength(1));
      expect(secondHalf.first.latitude, closeTo(48.1173, 0.0001));
    });

    test('ignores non-location lines and keeps the buffer aligned', () {
      final parser = BleLocationFrameParser();

      final fixes = parser.addBytes(
        'AT+OK\r\n\$GPRMC,123519,A,4807.038,N,01131.000,E,000.0,000.0,230394,003.1,W\r\n'
            .codeUnits,
      );

      expect(fixes, hasLength(1));
      expect(fixes.first.speedMps, 0);
    });
  });

  group('BleLocationFrameParser — JSON', () {
    test('decodes a JSON line with knots and ISO timestamp', () {
      final parser = BleLocationFrameParser();

      final fix = parser.parseLine(
        '{"lat":48.1173,"lon":11.5167,"speedKnots":10,"bearing":90,'
        '"altitude":12,"accuracy":3,"timestamp":"2026-11-13T10:00:00Z"}',
      );

      expect(fix, isNotNull);
      expect(fix!.latitude, closeTo(48.1173, 0.0001));
      expect(fix.longitude, closeTo(11.5167, 0.0001));
      expect(fix.speedMps, closeTo(5.1444, 0.001));
      expect(fix.protocol, 'json');
      expect(fix.timestamp.toUtc().year, 2026);
    });

    test('accepts speed already expressed in m/s', () {
      final parser = BleLocationFrameParser();

      final fix = parser.parseLine(
        '{"latitude":1.5,"longitude":2.5,"speed":7.2}',
      );

      expect(fix, isNotNull);
      expect(fix!.speedMps, closeTo(7.2, 0.001));
    });

    test('returns null for JSON without coordinates', () {
      final parser = BleLocationFrameParser();

      expect(parser.parseLine('{"speed":10}'), isNull);
      expect(parser.parseLine('not json at all'), isNull);
    });
  });

  group('BleLocationFix', () {
    test('converts m/s to the native map expected by pushLocation', () {
      final fix = BleLocationFix(
        latitude: 10,
        longitude: 20,
        speedMps: 12.5,
        bearing: 45,
        altitude: 3,
        accuracy: 5,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        protocol: 'json',
        alarm: 'sos',
      );

      final map = fix.toNativeMap();

      expect(map['latitude'], 10);
      expect(map['speed'], 12.5);
      expect(map['source'], 'ble');
      expect(map['alarm'], 'sos');
      expect(
        map['timestamp'],
        DateTime.utc(2026, 1, 2, 3, 4, 5).millisecondsSinceEpoch,
      );
    });

    test('rejects null island and out-of-range coordinates', () {
      BleLocationFix build(double lat, double lon) => BleLocationFix(
        latitude: lat,
        longitude: lon,
        speedMps: 0,
        bearing: 0,
        altitude: 0,
        accuracy: 0,
        timestamp: DateTime.utc(2026),
        protocol: 'json',
      );

      expect(build(0, 0).isValid, isFalse);
      expect(build(91, 0).isValid, isFalse);
      expect(build(0, 181).isValid, isFalse);
      expect(build(24.7, 46.7).isValid, isTrue);
    });
  });

  group('BLE device catalog', () {
    test('recognises Pacific Track by MAC prefix', () {
      final profile = matchBleDeviceProfile(
        name: 'Unknown',
        macAddress: 'E0:B4:88:C7:CA:E9',
      );

      expect(profile?.id, 'pacific_track_pt30');
    });

    test('recognises PT30 by advertised name', () {
      final profile = matchBleDeviceProfile(
        name: 'PT30-U 1234',
        macAddress: 'AA:BB:CC:DD:EE:FF',
      );

      expect(profile?.id, 'pacific_track_pt30');
    });

    test('recognises NUS and FFE0 devices by service UUID', () {
      expect(
        matchBleDeviceProfile(
          name: 'Unknown',
          macAddress: 'AA:BB:CC:DD:EE:FF',
          serviceUuids: [nusServiceUuid],
        )?.id,
        'generic_nus',
      );
      expect(
        matchBleDeviceProfile(
          name: 'Unknown',
          macAddress: 'AA:BB:CC:DD:EE:FF',
          serviceUuids: [ffe0ServiceUuid],
        )?.id,
        'generic_ffe0',
      );
    });

    test('normalises MAC typed without separators', () {
      expect(normalizeMacAddress('e0b488c7cae9'), 'E0:B4:88:C7:CA:E9');
      expect(normalizeMacAddress('E0-B4-88-C7-CA-E9'), 'E0:B4:88:C7:CA:E9');
      expect(normalizeMacAddress('not a mac'), 'NOT A MAC');
    });

    test('describes native kind values', () {
      expect(describeBleKind('pacificTrack'), 'Pacific Track');
      expect(describeBleKind('nus'), 'NUS UART');
      expect(describeBleKind('ffe0'), 'FFE0 UART');
      expect(describeBleKind(null), 'Unknown');
    });
  });

  group('bytesFromCommaSeparated', () {
    test('parses the legacy native payload format', () {
      expect(bytesFromCommaSeparated('36,71,80,82'), [36, 71, 80, 82]);
      expect(bytesFromCommaSeparated('  1 , 2 ,bad'), [1, 2]);
      expect(bytesFromCommaSeparated(''), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/data/models/unidentified_event_dto.dart';

void main() {
  test('server list uses id and the documented response fields', () {
    final items = parseUnidentifiedList({
      'items': [
        {
          'id': 88,
          'deviceId': 4,
          'vehicleName': 'Truck 4',
          'vehicleVin': '1FUJBBCF4BL123456',
          'startTime': '2026-09-23T01:00:00Z',
          'endTime': '2026-09-23T02:00:00Z',
          'durationMinutes': 60,
          'durationFormatted': '1h 0m',
          'latitude': 34.0522,
          'longitude': -118.2437,
          'locationDescription': 'I-5',
          'odometerMiles': 125430.5,
          'engineHours': 3450.2,
          'status': 'UNCLAIMED',
          'allocationType': 'UNASSIGNED',
          'allocatedToDriverId': 10,
          'annotation': 'Yard move',
          'rejectionReason': '',
          'pendingOver8Days': true,
        },
      ],
    });

    expect(items, hasLength(1));
    expect(items.single['id'], 88);
    expect(items.single['deviceId'], 4);
    expect(items.single['vehicleVin'], '1FUJBBCF4BL123456');
    expect(items.single['durationFormatted'], '1h 0m');
    expect(items.single['locationDescription'], 'I-5');
    expect(items.single['odometerMiles'], 125430.5);
    expect(items.single['engineHours'], 3450.2);
    expect(items.single['status'], 'UNCLAIMED');
    expect(items.single['allocationType'], 'UNASSIGNED');
    expect(items.single['pendingOver8Days'], isTrue);
  });

  test('a row without a server id cannot be claimed', () {
    final item = normalizeUnidentifiedItem({
      'status': 'UNCLAIMED',
      'startTime': '2026-09-23T01:00:00Z',
    });

    expect(item['id'], isNull);
  });

  test('summary uses the documented counters and 8-day alert', () {
    final summary = parseUnidentifiedSummary({
      'totalUnclaimed': 3,
      'totalRejected': 1,
      'pendingOver8DaysCount': 2,
      'complianceAlertActive': true,
    });

    expect(summary.totalUnclaimed, 3);
    expect(summary.totalRejected, 1);
    expect(summary.total, 4);
    expect(summary.pendingOver8DaysCount, 2);
    expect(summary.complianceAlertActive, isTrue);
  });

  test('a single event is parsed from the detail response', () {
    final event = parseUnidentifiedEvent({
      'id': 104,
      'deviceId': 4,
      'vehicleName': 'Truck-01',
      'vehicleVin': '1FUJBBCF4BL123456',
      'startTime': '2026-10-09T08:30:00Z',
      'endTime': '2026-10-09T09:15:00Z',
      'durationMinutes': 45,
      'durationFormatted': '0h 45m',
      'latitude': 34.0522,
      'longitude': -118.2437,
      'locationDescription': '5 mi S of Los Angeles, CA',
      'odometerMiles': 125430.5,
      'engineHours': 3450.2,
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'allocatedToDriverId': 10,
      'annotation': 'Yard move during loading',
      'rejectionReason': '',
      'pendingOver8Days': false,
    });

    expect(event.id, 104);
    expect(event.deviceId, 4);
    expect(event.vehicleVin, '1FUJBBCF4BL123456');
    expect(event.durationFormatted, '0h 45m');
    expect(event.locationDescription, '5 mi S of Los Angeles, CA');
    expect(event.odometerMiles, 125430.5);
    expect(event.engineHours, 3450.2);
    expect(event.annotation, 'Yard move during loading');
  });

  test('an empty successful payload stays empty', () {
    expect(parseUnidentifiedList({'items': const []}), isEmpty);
    expect(parseUnidentifiedList(const {}), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';

/// SRS 7.1 — vehicle operational status is derived from the report's
/// non-cleared defects only: OUT_OF_SERVICE when the server flags one,
/// RESTRICTED for any other open defect, AVAILABLE otherwise. The defect
/// status is never merged into the vehicle status field.
void main() {
  DvirReport report({
    bool hasDefects = false,
    bool outOfService = false,
  }) =>
      DvirReport(
        id: 'dvir-1',
        type: InspectionType.preTrip,
        date: DateTime.utc(2026, 9, 28),
        driverName: 'Driver',
        vehicleId: 'vehicle-1',
        items: const [],
        hasDefects: hasDefects,
        outOfService: outOfService,
      );

  test('no defects → AVAILABLE', () {
    expect(
      report().vehicleOperationalStatus,
      VehicleOperationalStatus.available,
    );
  });

  test('open non-OOS defects → RESTRICTED', () {
    expect(
      report(hasDefects: true).vehicleOperationalStatus,
      VehicleOperationalStatus.restricted,
    );
  });

  test('server-flagged out-of-service defect → OUT_OF_SERVICE', () {
    expect(
      report(hasDefects: true, outOfService: true).vehicleOperationalStatus,
      VehicleOperationalStatus.outOfService,
    );
  });

  test('outOfService flag wins over plain defects (SRS: no field merging)',
      () {
    // OOS dominates even though other defects are also open; the two
    // concepts stay separate fields and are never merged into one value.
    final r = report(hasDefects: true, outOfService: true);
    expect(r.vehicleOperationalStatus, VehicleOperationalStatus.outOfService);
    expect(r.hasDefects, isTrue);
    expect(r.outOfService, isTrue);
  });
}

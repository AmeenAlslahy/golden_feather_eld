import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/inspection/presentation/widgets/inspection_log_header_table.dart';

void main() {
  DotInspectionLog makeLog({
    required DateTime logDate,
    required String displayDate,
    String? period24HourStartTime = '00:00:00',
  }) {
    return DotInspectionLog(
      driverId: const DriverId(101),
      driverName: 'Ahmed Driver',
      logDate: logDate,
      displayDate: displayDate,
      displayLocation: 'Roadside Inspection Station',
      certified: true,
      certifiedAt: DateTime(2026, 10, 14, 10, 0),
      eldRegistrationId: 'ELD-REG-123',
      eldIdentifier: 'ELD-ID-456',
      eldProvider: 'GF Provider',
      vehicleNumber: 'Truck 100',
      uniqueId: 'TRK-100',
      vin: '1FUJGLDR5CSBJ0527',
      startOdometerKm: 1000.0,
      endOdometerKm: 1200.0,
      totalDistanceKm: 200.0,
      engineHours: 10.5,
      trailers: 'TR-1',
      shippingDocuments: 'BOL-99',
      carrierName: 'Carrier Inc',
      usdotNumber: '123456',
      mainOfficeAddress: 'Main St',
      homeTerminalAddress: 'Terminal Rd',
      activeDataDiagnostics: const [],
      activeDeviceMalfunctions: const [],
      events: const [],
      readOnly: true,
      period24HourStartTime: period24HourStartTime,
    );
  }

  group('InspectionLogHeaderTable', () {
    testWidgets('shows separate Log Date and Display Date correctly', (tester) async {
      final log = makeLog(
        logDate: DateTime(2026, 10, 13),
        displayDate: '2026-10-14',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectionLogHeaderTable(log: log),
            ),
          ),
        ),
      );

      // Log Date formatted as MMMM d, yyyy
      expect(find.text('October 13, 2026'), findsOneWidget);
      // Display Date formatted as MMMM d, yyyy
      expect(find.text('October 14, 2026'), findsOneWidget);
      // Period 24 start time
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('extracts Log Date from DotInspectionCycleDay when log is absent', (tester) async {
      final day = DotInspectionCycleDay(
        driverId: const DriverId(101),
        driverName: 'Ahmed Driver',
        logDate: DateTime(2026, 10, 12),
        displayDate: '2026-10-14',
        displayLocation: 'Inspection Point',
        certified: false,
        certifiedAt: null,
        eldRegistrationId: 'REG',
        eldIdentifier: 'ID',
        eldProvider: 'PROV',
        vehicleNumber: 'V1',
        uniqueId: 'U1',
        vin: 'VIN1',
        startOdometerKm: 0,
        endOdometerKm: 0,
        totalDistanceKm: 0,
        engineHours: 0,
        trailers: '',
        shippingDocuments: '',
        carrierName: 'Carrier',
        usdotNumber: '',
        mainOfficeAddress: '',
        homeTerminalAddress: '',
        activeDataDiagnostics: const [],
        activeDeviceMalfunctions: const [],
        exemptDriver: false,
        hasUnidentifiedDriving: false,
        unidentifiedDrivingCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectionLogHeaderTable(day: day),
            ),
          ),
        ),
      );

      expect(find.text('October 12, 2026'), findsOneWidget);
      expect(find.text('October 14, 2026'), findsOneWidget);
    });
  });
}

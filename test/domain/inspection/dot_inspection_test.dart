import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

void main() {
  group('DotInspectionScreen', () {
    test('constructs with required fields', () {
      final screen = DotInspectionScreen(
        screenTitle: 'DOT',
        guidanceText: 'Review',
        handOverDeviceNotice: 'Hand over',
        carrierComplianceStatement: 'Compliant',
        carrierName: 'Carrier',
        usdotNumber: '123',
        eldIdentifier: 'ELD-1',
        eldRegistrationId: 'REG-1',
        driverId: const DriverId(101),
        driverName: 'Ahmed',
        inspectionDate: DateTime.utc(2026, 1, 15),
        cycleDaysCovered: 8,
        canStartInspection: true,
        canSendLogs: true,
        canEmailLogs: true,
        canViewInformationPacket: true,
        inspectionActive: false,
        readOnlyMode: false,
      );
      expect(screen.driverId.value, 101);
      expect(screen.carrierName, 'Carrier');
    });
  });

  group('DotInspectionCycleDay', () {
    test('constructs with required fields', () {
      final day = DotInspectionCycleDay(
        driverId: const DriverId(101),
        driverName: 'Ahmed',
        logDate: DateTime.utc(2026, 1, 15),
        displayDate: '2026-01-15',
        displayLocation: 'Riyadh',
        certified: true,
        certifiedAt: DateTime.utc(2026, 1, 16),
        eldRegistrationId: 'REG',
        eldIdentifier: 'ID',
        eldProvider: 'Prov',
        vehicleNumber: '1',
        uniqueId: '1',
        vin: 'VIN123',
        startOdometerKm: 0,
        endOdometerKm: 10,
        totalDistanceKm: 10,
        engineHours: 1,
        trailers: '',
        shippingDocuments: '',
        carrierName: 'Carrier',
        usdotNumber: '123',
        mainOfficeAddress: 'Riyadh',
        homeTerminalAddress: 'Riyadh',
        activeDataDiagnostics: [],
        activeDeviceMalfunctions: [],
        exemptDriver: false,
        hasUnidentifiedDriving: false,
        unidentifiedDrivingCount: 0,
      );
      expect(day.driverName, 'Ahmed');
    });
  });

  group('DotInspectionLog', () {
    test('constructs with required fields', () {
      final log = DotInspectionLog(
        driverId: const DriverId(101),
        driverName: 'Ahmed',
        logDate: DateTime.utc(2026, 1, 15),
        displayDate: '2026-01-15',
        displayLocation: 'Riyadh',
        certified: true,
        certifiedAt: null,
        eldRegistrationId: 'REG',
        eldIdentifier: 'ID',
        eldProvider: 'Prov',
        vehicleNumber: '1',
        uniqueId: '1',
        vin: 'VIN123',
        startOdometerKm: 0,
        endOdometerKm: 10,
        totalDistanceKm: 10,
        engineHours: 1,
        trailers: '',
        shippingDocuments: '',
        carrierName: 'Carrier',
        usdotNumber: '123',
        mainOfficeAddress: 'Riyadh',
        homeTerminalAddress: 'Riyadh',
        activeDataDiagnostics: [],
        activeDeviceMalfunctions: [],
        events: [],
        readOnly: false,
      );
      expect(log.driverId.value, 101);
    });
  });
}

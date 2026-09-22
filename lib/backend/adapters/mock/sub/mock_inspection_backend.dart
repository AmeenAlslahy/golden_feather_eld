import '../../../../core/domain/inspection/dot_inspection.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/inspection_backend.dart';
import '../../../contracts/raw_json.dart';

class MockInspectionBackend implements InspectionBackend {
  MockInspectionBackend();

  final Map<String, DotInspectionLog> _logs = {};

  @override
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId}) async {
    return ok(
      DotInspectionScreen(
        screenTitle: 'DOT Inspection',
        guidanceText: 'Review the driver records',
        handOverDeviceNotice: 'Hand the device to the inspector',
        carrierComplianceStatement:
            'This device is compliant with FMCSA 49 CFR Part 395',
        carrierName: 'Golden Feather Transport',
        usdotNumber: '1234567',
        eldIdentifier: 'GF-ELD-001',
        eldRegistrationId: 'GF10000001',
        driverId: driverId ?? const DriverId(101),
        driverName: 'Ahmed',
        inspectionDate: DateTime.utc(2026, 1, 15),
        cycleDaysCovered: 8,
        canStartInspection: true,
        canSendLogs: true,
        canEmailLogs: true,
        canViewInformationPacket: true,
        inspectionActive: false,
        readOnlyMode: false,
      ),
    );
  }

  @override
  Future<Result<List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) async {
    final effectiveEnd = endDate ?? DateTime.utc(2026, 1, 15);
    return ok(
      List.generate(days, (i) {
        final date = effectiveEnd.subtract(Duration(days: i));
        return DotInspectionCycleDay(
          driverId: driverId ?? const DriverId(101),
          driverName: 'Ahmed',
          logDate: date,
          displayDate: _formatDate(date),
          displayLocation: 'Riyadh',
          certified: true,
          certifiedAt: date.add(const Duration(hours: 18)),
          eldRegistrationId: 'GF10000001',
          eldIdentifier: 'GF-ELD-001',
          eldProvider: 'Golden Feather',
          vehicleNumber: '646',
          uniqueId: '1001',
          vin: '1FUJGLDR5CSBJ0527',
          startOdometerKm: 125000.0,
          endOdometerKm: 125450.0,
          totalDistanceKm: 450.0,
          engineHours: 3500.0,
          trailers: '1402',
          shippingDocuments: 'BOL-001',
          carrierName: 'Golden Feather Transport',
          usdotNumber: '1234567',
          mainOfficeAddress: '123 Main St, Riyadh',
          homeTerminalAddress: '456 Terminal Rd, Dammam',
          activeDataDiagnostics: const [],
          activeDeviceMalfunctions: const [],
          exemptDriver: false,
          hasUnidentifiedDriving: false,
          unidentifiedDrivingCount: 0,
        );
      }),
    );
  }

  @override
  Future<Result<DotInspectionLog>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) async {
    final effectiveDate = date ?? DateTime.utc(2026, 1, 15);
    final key = _formatDate(effectiveDate);

    return ok(
      _logs.putIfAbsent(
        key,
        () => DotInspectionLog(
          driverId: driverId ?? const DriverId(101),
          driverName: 'Ahmed',
          logDate: effectiveDate,
          displayDate: key,
          displayLocation: 'Riyadh',
          certified: true,
          certifiedAt: effectiveDate.add(const Duration(hours: 18)),
          eldRegistrationId: 'GF10000001',
          eldIdentifier: 'GF-ELD-001',
          eldProvider: 'Golden Feather',
          vehicleNumber: '646',
          uniqueId: '1001',
          vin: '1FUJGLDR5CSBJ0527',
          startOdometerKm: 125000.0,
          endOdometerKm: 125450.0,
          totalDistanceKm: 450.0,
          engineHours: 3500.0,
          trailers: '1402',
          shippingDocuments: 'BOL-001',
          carrierName: 'Golden Feather Transport',
          usdotNumber: '1234567',
          mainOfficeAddress: '123 Main St, Riyadh',
          homeTerminalAddress: '456 Terminal Rd, Dammam',
          activeDataDiagnostics: const [],
          activeDeviceMalfunctions: const [],
          events: [
            const DotInspectionEvent(
              sequenceNumber: 1,
              timeEt: '06:00',
              eventCode: 'ON',
              eventType: 'on_duty',
              description: 'Start of shift',
              location: 'Riyadh',
              odometer: 125000.0,
              engineHours: 3500.0,
              origin: 'auto',
              notes: '',
              certificationEvent: false,
            ),
          ],
          readOnly: false,
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('MockInspectionBackend.emailLogs — Phase 2');

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getInformationPacket — Phase 2');

  @override
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('MockInspectionBackend.sendLogs — Phase 2');

  @override
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  }) =>
      throw UnimplementedError('MockInspectionBackend.startInspection — Phase 2');

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getTransfers — Phase 2');

  @override
  Future<Result<List<dynamic>>> getLegacyInspectionReport(int driverId) async {
    return ok([]);
  }

  @override
  Future<Result<void>> exportLegacyInspectionData(
      int driverId, String method, String? email, bool isErods) async {
    return ok(null);
  }
}

import '../api_endpoints.dart';

class EldServerEndpoints implements ApiEndpoints {
  @override
  String get basePath => '/api/v1/tracker/traccar';

  // Auth & Session
  @override
  String get session => '$basePath/session';
  @override
  String get logIn => '$basePath/session';
  @override
  String get logout => '$basePath/logout';
  @override
  String get logoutMethod => 'POST';

  // Users
  @override
  String get users => '$basePath/users';
  @override
  String get register => '$basePath/users';

  // Devices
  @override
  String get devices => '$basePath/devices';

  // Positions & Tracking
  @override
  String get positions => '$basePath/positions';
  @override
  String get events => '$basePath/events';

  // Reports
  @override
  String get reportSummary => '$basePath/reports/summary';
  @override
  String get reportRoute => '$basePath/reports/route';
  @override
  String get reportEvents => '$basePath/reports/events';
  @override
  String get reportTrips => '$basePath/reports/trips';
  @override
  String get reportStops => '$basePath/reports/stops';

  // ELD Specific (Nano3Tracker)
  @override
  String get drivers => '$basePath/drivers';

  @override
  String driverDutyStatus(int driverId) => '$drivers/$driverId/duty-status';

  @override
  String get dutyStatusLogs => '$basePath/duty-status-logs';

  @override
  String driverInspectionReport(int driverId) =>
      '$drivers/$driverId/inspection-report';

  @override
  String submitInspection() =>
      '$basePath/inspections'; // Assuming this is correct or similar to driverInspectionReport

  // ELD Reports & Export
  @override
  String eldComprehensiveReport(int driverId) =>
      '$drivers/$driverId/comprehensive-eld-report';

  @override
  String eldHosReport(int driverId) => '$drivers/$driverId/hos-report';

  @override
  String eldExportReport(int driverId) =>
      '$drivers/eld-report/export/$driverId';

  @override
  String inspectionExport(int driverId) =>
      '$drivers/$driverId/inspection-export';
}

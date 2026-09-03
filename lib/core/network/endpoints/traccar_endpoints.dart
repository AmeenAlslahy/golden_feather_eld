import '../api_endpoints.dart';

class TraccarEndpoints implements ApiEndpoints {
  @override
  String get basePath => '/api';

  // Auth & Session
  @override
  String get session => '$basePath/session';
  @override
  String get logIn => '$basePath/session';
  @override
  String get logout => '$basePath/session';
  @override
  String get logoutMethod => 'DELETE';

  // Users
  @override
  String get users => '$basePath/users';
  @override
  String get register => '$basePath/users'; // Traccar uses /users for registration

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

  // ELD Specific (Nano3Tracker) - Traccar doesn't have these natively
  @override
  String get drivers => '$basePath/unsupported/drivers';
  
  @override
  String driverDutyStatus(int driverId) => '$basePath/unsupported/drivers/$driverId/duty-status';
  
  @override
  String get dutyStatusLogs => '$basePath/unsupported/duty-status-logs';
  
  @override
  String driverInspectionReport(int driverId) => '$basePath/unsupported/drivers/$driverId/inspection-report';
  
  @override
  String submitInspection() => '$basePath/unsupported/inspection';
  
  // ELD Reports & Export
  @override
  String eldComprehensiveReport(int driverId) => '$basePath/unsupported/comprehensive-eld-report';
  
  @override
  String eldHosReport(int driverId) => '$basePath/unsupported/hos-report';
  
  @override
  String eldExportReport(int driverId) => '$basePath/unsupported/eld-report/export';

  @override
  String inspectionExport(int driverId) => '$basePath/unsupported/inspection-export';
}

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

  // ELD Specific - Traccar doesn't have these, so we mock or return unsupported paths
  @override
  String driverCompliance(String driverId) =>
      '$basePath/unsupported/compliance';

  @override
  String driverDiagnostics(String driverId) =>
      '$basePath/unsupported/diagnostics';

  @override
  String submitInspection() => '$basePath/unsupported/inspection';

  @override
  String eldComprehensiveReport(int driverId) {
    // TODO: implement eldComprehensiveReport
    throw UnimplementedError();
  }

  @override
  String eldExportReport(int driverId) {
    throw UnimplementedError();
  }

  @override
  String eldHosReport(int driverId) {
    throw UnimplementedError();
  }

  @override
  String inspectionExport(int driverId) {
    throw UnimplementedError();
  }
}

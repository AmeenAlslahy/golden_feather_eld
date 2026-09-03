abstract class ApiEndpoints {
  // Base Path
  String get basePath;

  // Auth & Session
  String get session;
  String get logIn;
  String get logout;
  String get logoutMethod;

  // Users
  String get users;
  String get register;

  // Devices
  String get devices;

  // Positions & Tracking
  String get positions;
  String get events;

  // Reports
  String get reportSummary;
  String get reportRoute;
  String get reportEvents;
  String get reportTrips;
  String get reportStops;

  // ELD Specific (Nano3Tracker)
  String get drivers;
  String driverDutyStatus(int driverId);
  String get dutyStatusLogs;
  String driverInspectionReport(int driverId);
  String submitInspection();
  
  // ELD Reports & Export
  String eldComprehensiveReport(int driverId);
  String eldHosReport(int driverId);
  String eldExportReport(int driverId);
  String inspectionExport(int driverId);
}

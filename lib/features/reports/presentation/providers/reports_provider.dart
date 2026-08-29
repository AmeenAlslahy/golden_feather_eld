import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/engine/diagnostics/diagnostics_engine.dart';
import '../../data/services/report_generator_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/engine/hos_violations_engine.dart';
import '../../../../core/engine/tracking/duty_status_tracker.dart';
import '../../../../core/services/event_log_service.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';

class _ReportParams {
  final String driverName;
  final String vehicleId;
  final Map<String, dynamic> todayStats;
  final Map<String, dynamic> weekStats;
  final List<Map<String, dynamic>> violations;
  final List<Map<String, dynamic>> displayEvents;
  final List<Map<String, dynamic>> diagnostics;
  final Map<String, dynamic> weeklyStats;
  final AppLocalizations loc;

  _ReportParams({
    required this.driverName,
    required this.vehicleId,
    required this.todayStats,
    required this.weekStats,
    required this.violations,
    required this.displayEvents,
    required this.diagnostics,
    required this.weeklyStats,
    required this.loc,
  });
}

class _ReportResult {
  final String eldJson;
  final String eldCsv;
  final String eldHtml;
  final String hosJson;
  final String hosCsv;
  final String hosHtml;

  _ReportResult({
    required this.eldJson,
    required this.eldCsv,
    required this.eldHtml,
    required this.hosJson,
    required this.hosCsv,
    required this.hosHtml,
  });
}

@pragma('vm:entry-point')
_ReportResult _generateReportsInBackground(_ReportParams params) {
  final date = DateTime.now().toString().substring(0, 10);

  final eldJson = ReportGeneratorService.generateEldReport(
    driverName: params.driverName,
    vehicleId: params.vehicleId,
    date: date,
    dailyStats: params.todayStats,
    events: params.displayEvents,
    diagnostics: params.diagnostics,
    isCertified: true,
    loc: params.loc,
    format: ReportFormat.json,
  );

  final eldCsv = ReportGeneratorService.generateEldReport(
    driverName: params.driverName,
    vehicleId: params.vehicleId,
    date: date,
    dailyStats: params.todayStats,
    events: params.displayEvents,
    diagnostics: params.diagnostics,
    isCertified: true,
    loc: params.loc,
    format: ReportFormat.csv,
  );

  final eldHtml = ReportGeneratorService.generateEldReport(
    driverName: params.driverName,
    vehicleId: params.vehicleId,
    date: date,
    dailyStats: params.todayStats,
    events: params.displayEvents,
    diagnostics: params.diagnostics,
    isCertified: true,
    loc: params.loc,
    format: ReportFormat.html,
  );

  final hosJson = ReportGeneratorService.generateHosReport(
    driverName: params.driverName,
    date: date,
    dailyStats: params.todayStats,
    weeklyStats: params.weeklyStats,
    periods: params.displayEvents,
    violations: params.violations,
    loc: params.loc,
    format: ReportFormat.json,
  );

  final hosCsv = ReportGeneratorService.generateHosReport(
    driverName: params.driverName,
    date: date,
    dailyStats: params.todayStats,
    weeklyStats: params.weeklyStats,
    periods: params.displayEvents,
    violations: params.violations,
    loc: params.loc,
    format: ReportFormat.csv,
  );

  final hosHtml = ReportGeneratorService.generateHosReport(
    driverName: params.driverName,
    date: date,
    dailyStats: params.todayStats,
    weeklyStats: params.weeklyStats,
    periods: params.displayEvents,
    violations: params.violations,
    loc: params.loc,
    format: ReportFormat.html,
  );

  return _ReportResult(
    eldJson: eldJson,
    eldCsv: eldCsv,
    eldHtml: eldHtml,
    hosJson: hosJson,
    hosCsv: hosCsv,
    hosHtml: hosHtml,
  );
}

/// حالة شاشة التقارير
class ReportsState {
  final String? eldReportJson;
  final String? eldReportCsv;
  final String? eldReportHtml;
  final String? hosReportJson;
  final String? hosReportCsv;
  final String? hosReportHtml;
  final bool isLoading;
  final DiagnosticsState diagnostics;

  const ReportsState({
    this.eldReportJson,
    this.eldReportCsv,
    this.eldReportHtml,
    this.hosReportJson,
    this.hosReportCsv,
    this.hosReportHtml,
    this.isLoading = false,
    this.diagnostics = const DiagnosticsState(),
  });

  ReportsState copyWith({
    String? eldReportJson,
    String? eldReportCsv,
    String? eldReportHtml,
    String? hosReportJson,
    String? hosReportCsv,
    String? hosReportHtml,
    bool? isLoading,
    DiagnosticsState? diagnostics,
  }) {
    return ReportsState(
      eldReportJson: eldReportJson ?? this.eldReportJson,
      eldReportCsv: eldReportCsv ?? this.eldReportCsv,
      eldReportHtml: eldReportHtml ?? this.eldReportHtml,
      hosReportJson: hosReportJson ?? this.hosReportJson,
      hosReportCsv: hosReportCsv ?? this.hosReportCsv,
      hosReportHtml: hosReportHtml ?? this.hosReportHtml,
      isLoading: isLoading ?? this.isLoading,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }
}

/// مزود التقارير
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});

class ReportsNotifier extends StateNotifier<ReportsState> {
  final Ref _ref;

  ReportsNotifier(this._ref) : super(const ReportsState()) {
    _loadDiagnostics();
  }

  Future<void> generateReports(AppLocalizations loc) async {
    state = state.copyWith(isLoading: true);

    // استخدام البيانات الحقيقية من المتتبعات
    final dutyTracker = _ref.read(dutyStatusTrackerProvider);
    final violationsEngine = _ref.read(hosViolationsEngineProvider);
    final eventLog = _ref.read(eventLogServiceProvider);
    final dashboard = _ref.read(dashboardDataProvider);

    final todayStats = dutyTracker.getTodayStats();
    final weekStats = dutyTracker.getWeekStats();

    // فحص الانتهاكات
    final violationsList = violationsEngine.checkAll(
      drivingHoursToday: todayStats['driving'] ?? 0,
      workHoursToday: (todayStats['driving'] ?? 0) + (todayStats['on_duty'] ?? 0),
      restHoursToday: (todayStats['off_duty'] ?? 0) + (todayStats['sleeper'] ?? 0),
      drivingHoursWeek: weekStats['driving'] ?? 0,
      consecutiveDays: 5, // يجب جلبه من HosCalculator مستقبلاً أو تتبع الأيام
      hasBreak: (todayStats['on_duty'] ?? 0) > 0,
      hasWeeklyRestart: (weekStats['rest'] ?? 0) > 34,
    );

    // تحويل الانتهاكات إلى التنسيق المطلوب
    final violations = violationsList.map((v) => {
      'type': v.type.name,
      'severity': v.level.englishName,
      'message': v.message,
    }).toList();

    // استخدام الأحداث الحقيقية
    final events = eventLog.getTodayEvents().map((e) => {
      'time': e.timestamp.toIso8601String(),
      'status': e.type, // افتراضياً، نوع الحدث هو الحالة
      'duration': 'N/A', // يمكن حسابه من الفترات
      'location': 'Unknown', // يمكن استخراجه من data
    }).toList();

    // إذا كانت الأحداث فارغة نعطي حدث افتراضي حتى لا يفشل التقرير تماماً في العرض
    final displayEvents = events.isNotEmpty ? events : [
      {'time': DateTime.now().toIso8601String(), 'status': dutyTracker.currentStatus.toString(), 'duration': '0h 0m', 'location': 'N/A'},
    ];

    // تشخيصات الأجهزة الحقيقية
    final diagnosticsEngine = _ref.read(diagnosticsEngineProvider);
    final diagnostics = diagnosticsEngine.state.activeMalfunctions.map((m) => {
      'type': m.type.name,
      'severity': m.severity.englishName,
      'message': m.message,
    }).toList();

    // إحصائيات أسبوعية
    final weeklyStats = <String, dynamic>{
      'total_driving': weekStats['driving'] ?? 0.0,
      'total_work': weekStats['work'] ?? 0.0,
      'total_rest': weekStats['rest'] ?? 0.0,
      'total_break': 0.0, // لم نتبع الاستراحات بالتفصيل
      'total_distance': weekStats['distance'] ?? 0.0,
      'available_today': 11.0 - (todayStats['driving'] ?? 0),
      'available_tomorrow': 11.0,
    };

    final params = _ReportParams(
      driverName: dashboard.driverName,
      vehicleId: dashboard.vehicleId,
      todayStats: todayStats,
      weekStats: weekStats,
      violations: violations,
      displayEvents: displayEvents,
      diagnostics: diagnostics,
      weeklyStats: weeklyStats,
      loc: loc,
    );

    final result = await compute(_generateReportsInBackground, params);

    state = state.copyWith(
      eldReportJson: result.eldJson,
      eldReportCsv: result.eldCsv,
      eldReportHtml: result.eldHtml,
      hosReportJson: result.hosJson,
      hosReportCsv: result.hosCsv,
      hosReportHtml: result.hosHtml,
      isLoading: false,
    );
  }

  void _loadDiagnostics() {
    final engine = _ref.read(diagnosticsEngineProvider);
    state = state.copyWith(diagnostics: engine.state);
  }

  void clearDiagnostics() {
    final engine = _ref.read(diagnosticsEngineProvider);
    engine.clearActive();
    _loadDiagnostics();
  }
}

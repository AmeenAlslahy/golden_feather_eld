import 'dart:convert';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/erods_generator.dart';
// import '../../../../core/utils/logger.dart'; // Uncomment if needed

/// أنواع التقارير
enum ReportType { eld, hos }

/// تنسيق التقرير
enum ReportFormat { json, csv, html, xml }

/// خدمة توليد التقارير
class ReportGeneratorService {
  /// توليد تقرير ELD
  static String generateEldReport({
    required String driverName,
    required String vehicleId,
    required String date,
    required Map<String, dynamic> dailyStats,
    required List<Map<String, dynamic>> events,
    required List<Map<String, dynamic>> diagnostics,
    required bool isCertified,
    required AppLocalizations loc,
    ReportFormat format = ReportFormat.json,
  }) {
    final reportData = {
      'report_type': loc.eldReport,
      'generated_at': DateTime.now().toIso8601String(),
      'timezone': DateTime.now().timeZoneName,
      'driver': {
        'name': driverName,
        'vehicle_id': vehicleId,
      },
      'date': date,
      'summary': {
        'driving_hours': dailyStats['driving'] ?? 0,
        'on_duty_hours': dailyStats['on_duty'] ?? 0,
        'off_duty_hours': dailyStats['off_duty'] ?? 0,
        'sleeper_hours': dailyStats['sleeper'] ?? 0,
        'is_certified': isCertified,
      },
      'events': events,
      'diagnostics': diagnostics,
    };

    return _formatReport(reportData, format, loc);
  }

  /// توليد تقرير HOS
  static String generateHosReport({
    required String driverName,
    required String date,
    required Map<String, dynamic> dailyStats,
    required Map<String, dynamic> weeklyStats,
    required List<Map<String, dynamic>> periods,
    required List<Map<String, dynamic>> violations,
    required AppLocalizations loc,
    ReportFormat format = ReportFormat.json,
  }) {
    final reportData = {
      'report_type': loc.hosReport,
      'generated_at': DateTime.now().toIso8601String(),
      'timezone': DateTime.now().timeZoneName,
      'driver': {
        'name': driverName,
      },
      'date': date,
      'summary': {
        'driving_hours': dailyStats['driving'] ?? 0,
        'work_hours': dailyStats['work'] ?? 0,
        'rest_hours': dailyStats['rest'] ?? 0,
        'break_hours': dailyStats['break'] ?? 0,
        'distance_km': dailyStats['distance'] ?? 0,
        'is_compliant': violations.isEmpty,
      },
      'weekly_summary': weeklyStats,
      'periods': periods,
      'violations': violations,
    };

    return _formatReport(reportData, format, loc);
  }

  /// تنسيق التقرير
  static String _formatReport(Map<String, dynamic> data, ReportFormat format, AppLocalizations loc) {
    switch (format) {
      case ReportFormat.json:
        return const JsonEncoder.withIndent('  ').convert(data);
      case ReportFormat.csv:
        return _toCsv(data, loc);
      case ReportFormat.html:
        return _toHtml(data, loc);
      case ReportFormat.xml:
        return ErodsGenerator.generateErodsXml(data);
    }
  }

  static String _toCsv(Map<String, dynamic> data, AppLocalizations loc) {
    final buffer = StringBuffer();
    final type = data['report_type'] ?? '';
    buffer.writeln('Report Type: $type');
    buffer.writeln('Generated: ${data['generated_at']}');
    buffer.writeln('Driver: ${data['driver']?['name'] ?? 'N/A'}');
    buffer.writeln();
    buffer.writeln('${loc.distance},Value');
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    summary.forEach((key, value) {
      buffer.writeln('$key,$value');
    });
    return buffer.toString();
  }

  static String _toHtml(Map<String, dynamic> data, AppLocalizations loc) {
    final type = data['report_type'] ?? '';
    final driver = data['driver']?['name'] ?? 'N/A';
    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    return '''
<!DOCTYPE html>
<html dir="ltr">
<head><meta charset="UTF-8"><title>$type Report</title></head>
<body>
  <h1>$type Report</h1>
  <p>Driver: $driver</p>
  <p>Generated: ${data['generated_at']}</p>
  <table border="1">
    <tr><th>${loc.distance}</th><th>Value</th></tr>
    ${summary.entries.map((e) => '<tr><td>${e.key}</td><td>${e.value}</td></tr>').join('')}
  </table>
</body>
</html>
''';
  }
}

/// مزود خدمة التقارير
final reportGeneratorServiceProvider = Provider<ReportGeneratorService>((ref) {
  return ReportGeneratorService();
});

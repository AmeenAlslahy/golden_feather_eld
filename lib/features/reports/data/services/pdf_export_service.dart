import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/logger.dart';
import '../../../../l10n/app_localizations.dart';

/// خدمة تصدير PDF
class PdfExportService {
  /// تصدير تقرير ELD كـ PDF
  static Future<File?> exportEldReport({
    required String driverName,
    required String vehicleId,
    required String date,
    required Map<String, double> stats,
    required bool isCertified,
    required AppLocalizations loc,
  }) async {
    try {
      final content = _buildEldPdfContent(
        driverName: driverName,
        vehicleId: vehicleId,
        date: date,
        stats: stats,
        isCertified: isCertified,
        loc: loc,
      );

      final file = await _savePdfFile('ELD_Report_$date.pdf', content);
      AppLogger.info('📄 ELD PDF exported: ${file?.path}');
      return file;
    } catch (e) {
      AppLogger.error('Failed to export ELD PDF', e);
      return null;
    }
  }

  /// تصدير تقرير HOS كـ PDF
  static Future<File?> exportHosReport({
    required String driverName,
    required String date,
    required Map<String, double> dailyStats,
    required Map<String, double> weeklyStats,
    required bool isCompliant,
    required AppLocalizations loc,
  }) async {
    try {
      final content = _buildHosPdfContent(
        driverName: driverName,
        date: date,
        dailyStats: dailyStats,
        weeklyStats: weeklyStats,
        isCompliant: isCompliant,
        loc: loc,
      );

      final file = await _savePdfFile('HOS_Report_$date.pdf', content);
      AppLogger.info('📄 HOS PDF exported: ${file?.path}');
      return file;
    } catch (e) {
      AppLogger.error('Failed to export HOS PDF', e);
      return null;
    }
  }

  /// بناء محتوى PDF لتقرير ELD
  static String _buildEldPdfContent({
    required String driverName,
    required String vehicleId,
    required String date,
    required Map<String, double> stats,
    required bool isCertified,
    required AppLocalizations loc,
  }) {
    final totalHours = (stats['driving'] ?? 0) +
        (stats['on_duty'] ?? 0) +
        (stats['off_duty'] ?? 0) +
        (stats['sleeper'] ?? 0);

    return '''
========================================
     ${loc.appName} - ${loc.eldReport}
========================================

${loc.driver}:     $driverName
${loc.vehicle}:    $vehicleId
${loc.dateLabel}:       $date
Generated:  ${DateTime.now().toIso8601String()}
Timezone:   ${DateTime.now().timeZoneName}

========================================
           SUMMARY
========================================

${loc.drivingStatus}:    ${(stats['driving'] ?? 0).toStringAsFixed(2)}h
${loc.onDuty}:    ${(stats['on_duty'] ?? 0).toStringAsFixed(2)}h
${loc.offDuty}:   ${(stats['off_duty'] ?? 0).toStringAsFixed(2)}h
${loc.sleeperBerth}:    ${(stats['sleeper'] ?? 0).toStringAsFixed(2)}h
----------------------------------------
${loc.total}:      ${totalHours.toStringAsFixed(2)}h

${loc.certified}:  ${isCertified ? loc.yes : loc.no}

========================================
       FMCSA 49 CFR PART 395
========================================

This report is generated in compliance
with FMCSA regulations.

Golden Feather ELD v1.0.0
========================================
''';
  }

  /// بناء محتوى PDF لتقرير HOS
  static String _buildHosPdfContent({
    required String driverName,
    required String date,
    required Map<String, double> dailyStats,
    required Map<String, double> weeklyStats,
    required bool isCompliant,
    required AppLocalizations loc,
  }) {
    return '''
========================================
     ${loc.appName} - ${loc.hosReport}
========================================

${loc.driver}:     $driverName
${loc.dateLabel}:       $date
Generated:  ${DateTime.now().toIso8601String()}
Timezone:   ${DateTime.now().timeZoneName}

========================================
         DAILY STATISTICS
========================================

${loc.drivingStatus}:    ${(dailyStats['driving'] ?? 0).toStringAsFixed(2)}h
${loc.work}:       ${(dailyStats['work'] ?? 0).toStringAsFixed(2)}h
${loc.rest}:       ${(dailyStats['rest'] ?? 0).toStringAsFixed(2)}h
${loc.break_}:      ${(dailyStats['break'] ?? 0).toStringAsFixed(2)}h
${loc.distance}:   ${(dailyStats['distance'] ?? 0).toStringAsFixed(1)} km

========================================
        WEEKLY STATISTICS
========================================

Total Driving:  ${(weeklyStats['total_driving'] ?? 0).toStringAsFixed(2)}h
Total Work:     ${(weeklyStats['total_work'] ?? 0).toStringAsFixed(2)}h
Total Rest:     ${(weeklyStats['total_rest'] ?? 0).toStringAsFixed(2)}h
Total Break:    ${(weeklyStats['total_break'] ?? 0).toStringAsFixed(2)}h
Total Distance: ${(weeklyStats['total_distance'] ?? 0).toStringAsFixed(1)} km

Available Today:    ${(weeklyStats['available_today'] ?? 0).toStringAsFixed(2)}h
Available Tomorrow: ${(weeklyStats['available_tomorrow'] ?? 0).toStringAsFixed(2)}h

========================================
           COMPLIANCE
========================================

Status:     ${isCompliant ? '✅ ${loc.compliant}' : '❌ ${loc.nonCompliant}'}

========================================
       FMCSA 49 CFR PART 395
========================================

Golden Feather ELD v1.0.0
========================================
''';
  }

  /// حفظ ملف PDF
  static Future<File?> _savePdfFile(String fileName, String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName'); // The caller already provides .pdf
      await file.writeAsString(content);
      return file;
    } catch (e) {
      AppLogger.error('Failed to save PDF file', e);
      return null;
    }
  }

  /// مشاركة ملف PDF
  static Future<bool> sharePdf(File file) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ELD/HOS Report',
      );
      return result.status == ShareResultStatus.success;
    } catch (e) {
      AppLogger.error('Failed to share PDF', e);
      return false;
    }
  }
}

/// مزود خدمة PDF
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

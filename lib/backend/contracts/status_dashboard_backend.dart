import '../../core/result/result.dart';
import '../../domain/duty_status/duty_status_code.dart';
import '../../domain/duty_status/status_dashboard.dart';
import '../../domain/duty_status/weekly_recap.dart';
import '../../domain/shared/value_objects.dart';

/// Contract for the status dashboard (main driver screen).
abstract interface class StatusDashboardBackend {
  /// GET /eld/status
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId});

  /// POST /eld/hos/status (المسار الحي الموثق في openapi الخادم 2026-10-30)
  ///
  /// [latitude]/[longitude] إحداثيات لحظة التغيير تُرسل داخل
  /// `location: {latitude, longitude}` **فقط** عند توفرهما معًا وقيمتهما
  /// ليست 0,0 — غيابهما يعني حذف الحقل كليًا (لا موقع مُختلَق).
  /// ملاحظة عقد: مخطط `UpdateStatusRequest` الحي لا يوثّق `location` بعد —
  /// الإرسال بقرار المالك ويحتاج تأكيد قبول الخادم.
  ///
  /// `null` = قبِل الخادم التغيير لكن استجابة POST لم تحمل لقطة لوحة
  /// (عقد مسموح: بعض الخوادم تُرجع سجل الحالة فقط). على المستدعي ألا
  /// يختلق أرقاماً عندها — اللوحة تُصحَّح من GET أو من مصدر أوفلاين.
  Future<Result<StatusDashboard?>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  });

  /// GET /eld/status/recap
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId});
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';

abstract class StatusDashboardRepository {
  /// Fetch the current status dashboard.
  Future<Either<Failure, StatusDashboard>> getDashboard({DriverId? driverId});

  /// Fetch the weekly recap data.
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap({DriverId? driverId});

  /// اللحظة (UTC) الموثوقة التي قِيست عندها اللوحة آخر مرة.
  ///
  /// الاستهلاك: `المتبقي الحيّ = متبقي الخادم − (الآن الموثوقة − هذه)`.
  ///
  /// `null` = لم تُقَس بعد؛ عندها يجب ختمها بلحظة استلام الاستجابة
  /// (استجابة حيّة من الخادم تُقاس لحظة وصولها).
  ///
  /// ⚠️ **هذا هو مصدر خطأ مطروح**: لو خُتمت هذه بلحظة "الآن" أثناء
  /// استرجاع لقطة من القرص، لأُلغيت مدة إغلاق التطبيق كاملة من الحساب
  /// — أي رصيد قانوني مُقدَّم بلا سند.
  DateTime? get snapshotAt;

  /// Cache a dashboard snapshot in memory and disk with its measurement timestamp.
  void cacheDashboard(StatusDashboard dashboard, {required DateTime takenAt});
}

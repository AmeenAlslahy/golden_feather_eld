import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../dvir_catalog.dart';
import '../entities/dvir_defect.dart';
import '../entities/dvir_report.dart';

abstract class DvirRepository {
  Future<Either<Failure, List<DvirReport>>> getDvirReports(String vehicleId);

  /// `GET /eld/dvir/pre-trip/{uniqueId}` — the server's designated source for
  /// the §396.13 previous-report review. `Right(null)` = server says there is
  /// no previous DVIR for this vehicle (`hasPreviousDvir:false`).
  Future<Either<Failure, DvirReport?>> getPreviousDvir(String vehicleId);
  Future<Either<Failure, DvirReport>> getDvirDetails(String id);

  /// §396.11 defect catalog from `GET /eld/dvir/catalog`.
  Future<Either<Failure, List<DvirCatalogItem>>> getDefectsCatalog();

  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
    required DvirConditionStatus status,
  });

  Future<Either<Failure, bool>> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  });

  /// تفاصيل عيب DVIR من الخادم (`GET /eld/dvir/defects/{id}`) — سجل
  /// الإصلاحات واعتمادات الناقل. قراءة شبكية فقط.
  Future<Either<Failure, DvirDefect>> getDefectDetails(int defectId);

  /// العيوب النشطة لمركبة السائق (`GET /eld/dvir/defects/device/{uniqueId}`):
  /// المفتوحة/قيد الإصلاح/بانتظار اعتماد الناقل.
  Future<Either<Failure, List<DvirDefect>>> getActiveDefects({
    required String uniqueId,
  });
}

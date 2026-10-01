import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/dvir_report.dart';

abstract class DvirRepository {
  Future<Either<Failure, List<DvirReport>>> getDvirReports(String vehicleId);

  /// `GET /eld/dvir/pre-trip/{uniqueId}` — the server's designated source for
  /// the §396.13 previous-report review. `Right(null)` = server says there is
  /// no previous DVIR for this vehicle (`hasPreviousDvir:false`).
  Future<Either<Failure, DvirReport?>> getPreviousDvir(String vehicleId);
  Future<Either<Failure, DvirReport>> getDvirDetails(String id);
  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
    required String status,
  });

  Future<Either<Failure, bool>> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  });
}

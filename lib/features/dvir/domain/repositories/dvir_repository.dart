import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/dvir_report.dart';

abstract class DvirRepository {
  Future<Either<Failure, List<DvirReport>>> getDvirReports(String vehicleId);
  Future<Either<Failure, DvirReport>> getDvirDetails(String id);
  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
    required String status,
  });
  Future<Either<Failure, bool>> certifyRepair({
    required String dvirId,
    required String mechanicName,
    required String action,
    String? repairNotes,
    required String mechanicSignature,
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

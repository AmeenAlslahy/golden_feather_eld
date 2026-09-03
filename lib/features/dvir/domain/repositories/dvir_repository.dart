import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/dvir_report.dart';

abstract class DvirRepository {
  Future<Either<Failure, List<DvirReport>>> getDvirReports(String vehicleId);
  Future<Either<Failure, bool>> submitDvirReport(DvirReport report);
}

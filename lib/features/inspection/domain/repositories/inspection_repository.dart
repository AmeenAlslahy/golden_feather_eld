import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/inspection_data.dart';

abstract class InspectionRepository {
  Future<Either<Failure, List<InspectionDayData>>> getInspectionReport(
      int driverId);
  Future<Either<Failure, bool>> exportInspectionData(
      // ignore: avoid_positional_boolean_parameters
      int driverId, TransferMethod method, String? email, bool isErods);
}

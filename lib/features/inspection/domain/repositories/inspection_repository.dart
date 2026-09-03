import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/inspection_data.dart';

abstract class InspectionRepository {
  Future<Either<Failure, List<InspectionDayData>>> getInspectionReport(int driverId);
  Future<Either<Failure, bool>> exportInspectionData(int driverId, TransferMethod method, String? email, bool isErods);
}

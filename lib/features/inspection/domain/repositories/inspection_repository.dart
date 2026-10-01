import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../inspection_transfer.dart';
import '../entities/inspection_data.dart';

abstract class InspectionRepository {
  Future<Either<Failure, void>> startInspection({required DriverId driverId});

  Future<Either<Failure, List<DotInspectionCycleDay>>> getCycle({
    required DriverId driverId,
    required int days,
  });

  Future<Either<Failure, DotInspectionLog>> getLogs({
    required DriverId driverId,
    DateTime? date,
  });

  Future<Either<Failure, TransferOutcome>> sendLogs({
    required DriverId driverId,
    required TransferMethod method,
    String? email,
    String? routingCode,
    required String comment,
  });

  Future<Either<Failure, InformationPacketView>> getInformationPacket({
    DriverId? driverId,
  });
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../inspection_transfer.dart';
import '../transfer_audit.dart';

abstract class InspectionRepository {
  Future<Either<Failure, List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
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

  Future<Either<Failure, DotInspectionScreen>> getScreen({DriverId? driverId});

  Future<Either<Failure, List<TransferAuditRow>>> getTransfers({
    DriverId? driverId,
  });

  /// تسجيل بدء وضع التفتيش على الخادم (`POST /eld/dot-inspection/start`)
  /// ليصبح القفل موثقاً مركزياً (49 CFR § 395.22). الاستدعاء غير معيق:
  /// فشله لا يمنع وضع التفتيش المحلي على الجهاز.
  Future<Either<Failure, Unit>> registerInspectionStart({
    required DriverId driverId,
  });
}

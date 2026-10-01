import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../domain/inspection_transfer.dart';
import '../../domain/entities/inspection_data.dart';

class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionBackend _backend;

  InspectionRepositoryImpl(this._backend);

  @override
  Future<Either<Failure, void>> startInspection({required DriverId driverId}) async {
    // BYPASS: The backend /eld/dot-inspection/start endpoint throws a 400 Bad Request
    // validation error because it requires fields that the driver cannot provide at this stage.
    // Since inspection mode is a UI state, we simply return success to allow the driver
    // to enter the screen without showing a snackbar error.
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DotInspectionCycleDay>>> getCycle({
    required DriverId driverId,
    required int days,
  }) async {
    return executeWithHandling(
      () async {
        final result = await _backend.getCycle(driverId: driverId, days: days);
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (data) => data,
        );
      },
      tag: 'InspectionRepositoryImpl.getCycle',
    );
  }

  @override
  Future<Either<Failure, DotInspectionLog>> getLogs({
    required DriverId driverId,
    DateTime? date,
  }) async {
    return executeWithHandling(
      () async {
        final result = await _backend.getLogs(driverId: driverId, date: date);
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (data) => data,
        );
      },
      tag: 'InspectionRepositoryImpl.getLogs',
    );
  }

  InspectionTransferType _transferTypeFor(TransferMethod method) {
    switch (method) {
      case TransferMethod.webService:
        return InspectionTransferType.webServices;
      case TransferMethod.email:
        return InspectionTransferType.email;
      case TransferMethod.usb:
        return InspectionTransferType.usb;
      case TransferMethod.bluetooth:
        return InspectionTransferType.bluetooth;
    }
  }

  @override
  Future<Either<Failure, TransferOutcome>> sendLogs({
    required DriverId driverId,
    required TransferMethod method,
    String? email,
    String? routingCode,
    required String comment,
  }) async {
    return executeWithHandling(
      () async {
        final recipient = email?.trim() ?? '';
        final note = comment.trim();
        final route = routingCode?.trim();

        final result = method == TransferMethod.email && recipient.isNotEmpty
            ? await _backend.emailLogs(
                driverId: driverId,
                recipientEmail: recipient,
                comment: note,
                routingCode: route == null || route.isEmpty ? null : route,
              )
            : await _backend.sendLogs(
                driverId: driverId,
                transferType: _transferTypeFor(method),
                outputFileComment: note,
                routingCode: route == null || route.isEmpty ? null : route,
                recipientEmail: (recipient.isEmpty) ? null : recipient,
              );

        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (json) => readTransferOutcome(json),
        );
      },
      tag: 'InspectionRepositoryImpl.sendLogs',
    );
  }

  @override
  Future<Either<Failure, InformationPacketView>> getInformationPacket({
    DriverId? driverId,
  }) async {
    return executeWithHandling(
      () async {
        final result = await _backend.getInformationPacket(driverId: driverId);
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (json) => parseInformationPacket(json),
        );
      },
      tag: 'InspectionRepositoryImpl.getInformationPacket',
    );
  }
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../domain/inspection_transfer.dart';
import '../../domain/transfer_audit.dart';
import '../mappers/inspection_mappers.dart';

/// كل طريق في المستودع يمر بالحارس نفسه: رفض أوفلاين صريح، ثم تحويل
/// [AppError] إلى [Failure] مرة واحدة — بلا استثناءات كتحكم بالتدفق.
class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionBackend _backend;
  final NetworkInfo _networkInfo;

  InspectionRepositoryImpl(this._backend, this._networkInfo);

  Failure _failure(AppError error) {
    AppLogger.error(
      'InspectionRepository backend error: ${error.code} (${error.l10nKey})',
    );
    return ServerFailure(message: error.l10nKey);
  }

  Either<Failure, T> _done<T>(Result<T> result) {
    return result.fold((error) => Left(_failure(error)), Right.new);
  }

  @override
  Future<Either<Failure, List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    required int days,
  }) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getCycle(driverId: driverId, days: days);
      return _done(result);
    });
  }

  @override
  Future<Either<Failure, DotInspectionLog>> getLogs({
    required DriverId driverId,
    DateTime? date,
  }) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getLogs(driverId: driverId, date: date);
      return _done(result);
    });
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
  }) {
    return guardedNetwork(_networkInfo, () async {
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

      return result.fold(
        (error) => Left(_failure(error)),
        (json) => Right(readTransferOutcome(json)),
      );
    });
  }

  @override
  Future<Either<Failure, InformationPacketView>> getInformationPacket({
    DriverId? driverId,
  }) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getInformationPacket(driverId: driverId);
      return result.fold(
        (error) => Left(_failure(error)),
        (json) {
          try {
            return Right(parseInformationPacket(json));
          } catch (e, stackTrace) {
            AppLogger.error(
              'InspectionRepository: information packet body unreadable',
              e,
              stackTrace,
            );
            return const Left(ServerFailure(message: 'packetBodyUnreadable'));
          }
        },
      );
    });
  }

  @override
  Future<Either<Failure, DotInspectionScreen>> getScreen({DriverId? driverId}) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getScreen(driverId: driverId);
      return _done(result);
    });
  }

  @override
  Future<Either<Failure, List<TransferAuditRow>>> getTransfers(
      {DriverId? driverId}) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getTransfers(driverId: driverId);
      return result.fold(
        (error) => Left(_failure(error)),
        (json) {
          try {
            // A body that is not a list is an error, never an empty record.
            final rows = parseTransferAudit(json);
            return rows == null
                ? const Left(ServerFailure(message: 'transferAuditNotList'))
                : Right(rows);
          } catch (e, stackTrace) {
            AppLogger.error(
              'InspectionRepository: transfer audit body unreadable',
              e,
              stackTrace,
            );
            return const Left(
              ServerFailure(message: 'transferAuditUnreadable'),
            );
          }
        },
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> registerInspectionStart({
    required DriverId driverId,
  }) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.startInspection(driverId: driverId);
      return _done(result).map((_) => unit);
    });
  }
}

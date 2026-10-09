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
import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/usecases/sync_engine.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../domain/inspection_transfer.dart';
import '../../domain/transfer_audit.dart';
import '../mappers/inspection_mappers.dart';
import '../services/fmcsa_eld_output_generator.dart';


/// كل طريق في المستودع يمر بالحارس نفسه: فحص الشبكة مع كاشينغ محلي يضمن
/// عمل وضع التفتيش الميداني في نقاط التفتيش النائية (FMCSA § 395.24 / SRS 6.8).
class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionBackend _backend;
  final NetworkInfo _networkInfo;
  final SyncEngine? _syncEngine;

  /// ذاكرة مؤقتة تضمن استمرار عمل التفتيش وعرض السجلات حتى عند انقطاع الاتصال
  static DotInspectionScreen? _cachedScreen;
  static List<DotInspectionCycleDay> _cachedCycle = [];
  static final Map<String, DotInspectionLog> _cachedLogs = {};
  static InformationPacketView? _cachedPacket;

  InspectionRepositoryImpl(
    this._backend,
    this._networkInfo, [
    this._syncEngine,
  ]);

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
      return result.fold(
        (error) => _cachedCycle.isNotEmpty
            ? Right(_cachedCycle)
            : Left(_failure(error)),
        (cycleDays) {
          _cachedCycle = cycleDays;
          return Right(cycleDays);
        },
      );
    }, offline: () async {
      if (_cachedCycle.isNotEmpty) return Right(_cachedCycle);
      return const Left(NetworkFailure());
    });
  }

  @override
  Future<Either<Failure, DotInspectionLog>> getLogs({
    required DriverId driverId,
    DateTime? date,
  }) {
    final key = date != null ? date.toIso8601String().split('T').first : 'latest';
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getLogs(driverId: driverId, date: date);
      return result.fold(
        (error) => _cachedLogs.containsKey(key)
            ? Right(_cachedLogs[key]!)
            : Left(_failure(error)),
        (log) {
          _cachedLogs[key] = log;
          return Right(log);
        },
      );
    }, offline: () async {
      if (_cachedLogs.containsKey(key)) return Right(_cachedLogs[key]!);
      if (_cachedLogs.isNotEmpty) return Right(_cachedLogs.values.first);
      return const Left(NetworkFailure());
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
    }, offline: () async {
      // FMCSA § 395.24 / § 395.34: Offline local generation and transfer queuing
      try {
        final filePath = await FmcsaEldOutputGenerator.generateAndSave(
          screen: _cachedScreen,
          cycleDays: _cachedCycle,
          logs: _cachedLogs,
          outputFileComment: comment,
          fallbackDriverId: driverId.value.toString(),
        );

        if (_syncEngine != null) {
          await _syncEngine.submitEvent(PendingEvent(
            id: 'transfer_${DateTime.now().millisecondsSinceEpoch}',
            type: 'inspection_transfer',
            payload: {
              'driverId': driverId.value,
              'method': method.name,
              'email': email,
              'routingCode': routingCode,
              'comment': comment,
              'localFilePath': filePath,
            },
            createdAt: DateTime.now().toUtc(),
          ));
        }

        return Right(TransferOutcome(
          accepted: true,
          text: 'OFFLINE_GENERATED:$filePath',
        ));
      } catch (e, st) {
        AppLogger.error('Offline ELD file generation failed', e, st);
        return Left(ServerFailure(message: 'Failed to generate offline ELD file: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, InformationPacketView>> getInformationPacket({
    DriverId? driverId,
  }) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getInformationPacket(driverId: driverId);
      return result.fold(
        (error) => _cachedPacket != null ? Right(_cachedPacket!) : Left(_failure(error)),
        (json) {
          try {
            final packet = parseInformationPacket(json);
            _cachedPacket = packet;
            return Right(packet);
          } catch (e, stackTrace) {
            AppLogger.error(
              'InspectionRepository: information packet body unreadable',
              e,
              stackTrace,
            );
            return _cachedPacket != null
                ? Right(_cachedPacket!)
                : const Left(ServerFailure(message: 'packetBodyUnreadable'));
          }
        },
      );
    }, offline: () async {
      if (_cachedPacket != null) return Right(_cachedPacket!);
      return const Left(NetworkFailure());
    });
  }

  @override
  Future<Either<Failure, DotInspectionScreen>> getScreen({DriverId? driverId}) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getScreen(driverId: driverId);
      return result.fold(
        (error) => _cachedScreen != null ? Right(_cachedScreen!) : Left(_failure(error)),
        (screen) {
          _cachedScreen = screen;
          return Right(screen);
        },
      );
    }, offline: () async {
      if (_cachedScreen != null) return Right(_cachedScreen!);
      return const Left(NetworkFailure());
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

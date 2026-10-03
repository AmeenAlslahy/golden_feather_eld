import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/repositories/offline_queue.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../backend/contracts/dvir_backend.dart';
import '../../../../backend/contracts/raw_json.dart';
import '../../../../core/result/result.dart';
import '../../../../backend/adapters/eld_engine/models/dvir_dto.dart';
import '../../../../domain/shared/value_objects.dart';
import '../mappers/dvir_mappers.dart';

class DvirRepositoryImpl implements DvirRepository {
  final DvirBackend dvirBackend;
  final NetworkInfo networkInfo;
  final OfflineQueue offlineQueue;
  final Uuid _uuid;

  DvirRepositoryImpl({
    required this.dvirBackend,
    required this.networkInfo,
    required this.offlineQueue,
  }) : _uuid = const Uuid();

  Failure _failure(AppError error) {
    AppLogger.error('DvirRepository backend error: ${error.code}');
    return ServerFailure(message: error.code);
  }

  @override
  Future<Either<Failure, List<DvirReport>>> getDvirReports(
    String vehicleId,
  ) async {
    return guardedNetwork(networkInfo, () async {
      // معرّف غير معيّن (فارغ أو "No Vehicle") يعني قائمة بلا تصفية مركبة.
      final result = isUnassignedVehicleId(vehicleId)
          ? await dvirBackend.list()
          : await dvirBackend.list(uniqueId: vehicleId);

      return result.fold((error) => Left(_failure(error)), (
        rawJson,
      ) {
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
        final reports = rawReports.map((json) {
          final dto = DvirDto.fromJson(json as Map<String, dynamic>);
          return _mapDtoToEntity(dto);
        }).toList();
        return Right(reports);
      });
    });
  }

  @override
  Future<Either<Failure, DvirReport?>> getPreviousDvir(String vehicleId) async {
    return guardedNetwork(networkInfo, () async {
      if (isUnassignedVehicleId(vehicleId)) {
        return const Right(null);
      }
      final Result<RawJson> result;
      try {
        result = await dvirBackend.getPreviousDvir(vehicleId.trim());
      } catch (e, stackTrace) {
        AppLogger.error('DvirRepository: pre-trip read failed', e, stackTrace);
        return const Left(ServerFailure(message: 'pre-trip read failed'));
      }
      return result.fold((error) => Left(_failure(error)), (
        raw,
      ) {
        final nested = raw['data'];
        final body = nested is Map ? Map<String, dynamic>.from(nested) : raw;
        // Live shape with no record: {message:"No Records", hasPreviousDvir:false}.
        if (body['hasPreviousDvir'] == false) return const Right(null);
        final candidate = _previousDvirObject(body);
        if (candidate == null) {
          // Caller falls back to the vehicle list; never guess a report.
          return const Left(
            ServerFailure(message: 'pre-trip body has no DVIR'),
          );
        }
        try {
          return Right(_mapDtoToEntity(DvirDto.fromJson(candidate)));
        } catch (e, stackTrace) {
          AppLogger.error(
            'DvirRepository: pre-trip body unreadable',
            e,
            stackTrace,
          );
          return const Left(ServerFailure(message: 'pre-trip body unreadable'));
        }
      });
    });
  }

  /// The record may be the body itself or nested under a documented-looking
  /// key; anything without an `id` is not a DVIR.
  static Map<String, dynamic>? _previousDvirObject(Map<String, dynamic> body) {
    if (body['id'] is num) return body;
    for (final key in const ['dvir', 'previousDvir', 'report', 'lastDvir']) {
      final value = body[key];
      if (value is Map && value['id'] is num) {
        return Map<String, dynamic>.from(value);
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, DvirReport>> getDvirDetails(String id) async {
    return guardedNetwork(networkInfo, () async {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return const Left(ServerFailure(message: 'Invalid DVIR ID'));
      }
      final result = await dvirBackend.getById(DvirId(parsedId));
      return result.fold((error) => Left(_failure(error)), (
        rawJson,
      ) {
        try {
          return Right(_mapDtoToEntity(DvirDto.fromJson(rawJson)));
        } catch (e, stackTrace) {
          AppLogger.error(
            'DvirRepository: failed to parse DVIR details',
            e,
            stackTrace,
          );
          return const Left(
            ServerFailure(message: 'Failed to parse DVIR details'),
          );
        }
      });
    });
  }

  @override
  Future<Either<Failure, List<DvirCatalogItem>>> getDefectsCatalog() async {
    return guardedNetwork(networkInfo, () async {
      final result = await dvirBackend.getDefectsCatalog();
      return result.fold((error) => Left(_failure(error)), (raw) {
        final items = parseDvirCatalog(raw);
        // جسم غير مقروء خطأ، وليس كتالوجاً فارغاً.
        return items == null
            ? const Left(ServerFailure(message: 'catalog body is not a list'))
            : Right(items);
      });
    });
  }

  @override
  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
    required DvirConditionStatus status,
  }) async {
    // SRS 6.8 — offline: enqueue DVIR for sync, never lose the driver's report.
    final body = _buildCreateBody(report, driverId: driverId, status: status);
    if (body == null) {
      return const Left(
        ServerFailure(message: 'Driver, vehicle, or signature is missing.'),
      );
    }
    if (!networkInfo.isConnected) {
      await offlineQueue.enqueue(
        PendingEvent(
          id: _uuid.v4(),
          type: 'dvir_create',
          payload: body,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return const Right(true);
    }
    return guardedNetwork(networkInfo, () async {
      final result = await dvirBackend.create(body);
      return result.fold(
        (error) => Left(_failure(error)),
        (_) => const Right(true),
      );
    });
  }

  Map<String, dynamic>? _buildCreateBody(
    DvirReport report, {
    required int driverId,
    required DvirConditionStatus status,
  }) {
    return buildDvirCreateBody(
      driverId: driverId,
      uniqueId: report.vehicleId,
      status: status.wire,
      signatureData: report.signature,
      inspectionTime: report.date.toUtc().toIso8601String(),
      location: report.location,
      odometer: report.odometer,
      trailerNumber: report.trailerId,
      companyName: report.companyName,
      remarks: report.notes,
      vehicleDefects: report.vehicleDefects,
      trailerDefects: report.trailerDefects,
      catalogDefects:
          report.selectedDefects.map(defectSelectionToWire).toList(),
    );
  }

  @override
  Future<Either<Failure, bool>> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async {
    final parsedId = int.tryParse(dvirId);
    if (parsedId == null) {
      return const Left(ServerFailure(message: 'Invalid DVIR ID for review'));
    }
    final dto = ReviewDvirRequestDto(
      reviewingDriverId: reviewingDriverId,
      reviewingDriverName: reviewingDriverName,
      signatureData: signatureData,
      driverAgreed: driverAgreed,
      reviewNotes: reviewNotes,
    );
    // SRS 6.8 / 7.9 — offline: enqueue §396.13 review for sync.
    if (!networkInfo.isConnected) {
      await offlineQueue.enqueue(
        PendingEvent(
          id: _uuid.v4(),
          type: 'dvir_review',
          payload: {
            'dvirId': parsedId,
            'review': dto.toJson(),
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return const Right(true);
    }
    return guardedNetwork(networkInfo, () async {
      final result = await dvirBackend.review(
        dvirId: DvirId(parsedId),
        review: dto.toJson(),
      );
      return result.fold(
        (error) => Left(_failure(error)),
        (_) => const Right(true),
      );
    });
  }

  DvirReport _mapDtoToEntity(DvirDto dto) {
    return DvirReport(
      id: dto.id.toString(),
      type: _parseInspectionType(dto.inspectionType),
      // وقت غير قابل للتحليل → الآن للعرض فقط؛ لا يُخترع تاريخ رسمي بديل
      // في أي مسار إرسال (الإرسال يبني وقته من TrustedTime).
      date: DateTime.tryParse(dto.inspectionTime ?? '') ?? DateTime.now(),
      driverName: dto.driver?.name ?? '',
      vehicleId: dto.uniqueId ?? '',
      trailerId: dto.trailerNumber,
      odometer: dto.odometer,
      condition: _parseVehicleCondition(dto.status),
      signature: dto.signatureData,
      notes: dto.remarks,
      isSubmitted: true,
      location: dto.location,
      companyName: dto.companyName,
      hasDefects: dto.hasDefects,
      defectsCount: dto.defectsCount,
      defectsSummary: dto.defectsSummary,
      outOfService: dto.outOfService,
      certified: dto.certified,
      mechanicName: dto.mechanicName,
      repairStatus: dto.repairStatus,
      repairNotes: dto.repairNotes,
      reviewingDriverName: dto.reviewingDriverName,
      nextDriverReviewed: dto.nextDriverReviewed,
      // Server defects with a catalog code are shown as catalog chips on the saved report.
      selectedDefects: [
        for (final defect in dto.defects)
          if ((defect.itemCode ?? '').trim().isNotEmpty)
            DvirDefectSelection(
              item: DvirCatalogItem(
                code: defect.itemCode!.trim(),
                name: defect.itemName ?? defect.itemCode!,
                category: defect.category ?? '',
                critical: defect.safetyAffecting || defect.outOfService,
              ),
              description: defect.description,
            ),
      ],
    );
  }

  InspectionType _parseInspectionType(String? type) {
    if (type == InspectionType.postTrip.name) return InspectionType.postTrip;
    return InspectionType.preTrip;
  }

  VehicleCondition _parseVehicleCondition(String? condition) {
    // الحالة الرسمية من الخادم عبر الـ enum؛ أي حالة غير معروفة تبقى
    // متحفظة (needsRepair) — الأمان يفضّل التحفظ على التفاؤل.
    final status = DvirConditionStatus.fromWire(condition);
    return status == DvirConditionStatus.satisfactory
        ? VehicleCondition.safe
        : VehicleCondition.needsRepair;
  }
}

import 'package:fpdart/fpdart.dart';

import '../../../../backend/adapters/eld_engine/models/dvir_dto.dart';
import '../../../../backend/contracts/dvir_backend.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';

class DvirRepositoryImpl implements DvirRepository {
  final DvirBackend dvirBackend;
  final NetworkInfo networkInfo;

  DvirRepositoryImpl({
    required this.dvirBackend,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<DvirReport>>> getDvirReports(
      String vehicleId) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    final result = await dvirBackend.list(uniqueId: vehicleId);
    
    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (rawJson) {
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
        final reports = rawReports.map((json) {
          final dto = DvirDto.fromJson(json as Map<String, dynamic>);
          return _mapDtoToEntity(dto);
        }).toList();
        return Right(reports);
      }
    );
  }

  @override
  Future<Either<Failure, DvirReport>> getDvirDetails(String id) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    final result = await dvirBackend.getById(DvirId(int.parse(id)));
    
    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (rawJson) {
        final dto = DvirDto.fromJson(rawJson);
        return Right(_mapDtoToEntity(dto));
      }
    );
  }

  @override
  Future<Either<Failure, bool>> submitDvirReport(DvirReport report) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    
    final defectsDto = report.items
        .where((item) => item.isDefective)
        .map((item) => DvirDefectDto(
              itemName: item.item.name,
              description: item.defectDescription,
            ))
        .toList();

    final dto = CreateDvirRequestDto(
      driverId: 0, // Should be passed correctly in a real scenario from auth
      uniqueId: report.vehicleId,
      vehicleName: report.vehicleId,
      inspectionType: report.type.name,
      inspectionTime: report.date.toIso8601String(),
      location: report.location,
      odometer: report.odometer,
      trailerNumber: report.trailerId,
      companyName: report.companyName,
      remarks: report.notes,
      status: report.condition.name,
      defects: defectsDto,
      signatureData: report.signature ?? '',
    );

    final result = await dvirBackend.create(dto.toJson());
    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  @override
  Future<Either<Failure, bool>> certifyRepair({
    required String dvirId,
    required String mechanicName,
    required String action,
    String? repairNotes,
    required String mechanicSignature,
  }) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());

    final dto = CertifyRepairRequestDto(
      mechanicName: mechanicName,
      action: action,
      repairNotes: repairNotes,
      mechanicSignature: mechanicSignature,
    );

    final result = await dvirBackend.certifyRepair(
      dvirId: DvirId(int.parse(dvirId)),
      repair: dto.toJson(),
    );

    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
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
    if (!networkInfo.isConnected) return const Left(NetworkFailure());

    final dto = ReviewDvirRequestDto(
      reviewingDriverId: reviewingDriverId,
      reviewingDriverName: reviewingDriverName,
      signatureData: signatureData,
      driverAgreed: driverAgreed,
      reviewNotes: reviewNotes,
    );

    final result = await dvirBackend.review(
      dvirId: DvirId(int.parse(dvirId)),
      review: dto.toJson(),
    );

    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  DvirReport _mapDtoToEntity(DvirDto dto) {
    return DvirReport(
      id: dto.id.toString(),
      type: _parseInspectionType(dto.inspectionType),
      date: DateTime.tryParse(dto.inspectionTime ?? '') ?? DateTime.now(),
      driverName: dto.driver?.name ?? '',
      vehicleId: dto.uniqueId ?? dto.id.toString(),
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
      items: dto.defects.map((defect) {
        return ItemInspectionResult(
          item: _parseInspectionItem(defect.itemName),
          isDefective: true,
          defectDescription: defect.description,
        );
      }).toList(),
    );
  }

  InspectionType _parseInspectionType(String? type) {
    if (type == InspectionType.postTrip.name) return InspectionType.postTrip;
    return InspectionType.preTrip;
  }

  VehicleCondition _parseVehicleCondition(String? condition) {
    if (condition == VehicleCondition.needsRepair.name) {
      return VehicleCondition.needsRepair;
    }
    if (condition == VehicleCondition.unsafe.name) {
      return VehicleCondition.unsafe;
    }
    return VehicleCondition.safe;
  }

  InspectionItem _parseInspectionItem(String? name) {
    return InspectionItem.values.firstWhere(
      (item) => item.name == name,
      orElse: () => InspectionItem.engine,
    );
  }
}

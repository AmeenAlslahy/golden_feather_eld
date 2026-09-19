import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../backend/contracts/dvir_backend.dart';

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
        final rawReports = (rawJson['reports'] as List<dynamic>?) ?? [];
        final reports = rawReports.map((json) {
        return DvirReport(
          id: json['id']?.toString() ?? '',
          type: _parseInspectionType(json['type']),
          date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
          driverName: json['driverName'] ?? '',
          vehicleId: json['vehicleId'] ?? '',
          trailerId: json['trailerId'],
          odometer: (json['odometer'] as num?)?.toDouble(),
          condition: _parseVehicleCondition(json['condition']),
          signature: json['signature'],
          notes: json['notes'],
          isSubmitted: true,
          items: (json['items'] as List<dynamic>?)?.map((item) {
                return ItemInspectionResult(
                  item: _parseInspectionItem(item['name']),
                  isDefective: item['isDefective'] ?? false,
                  defectDescription: item['defectDescription'],
                );
              }).toList() ??
              [],
        );
      }).toList();

        return Right(reports);
      }
    );
  }

  @override
  Future<Either<Failure, bool>> submitDvirReport(DvirReport report) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    final data = {
      'id': report.id,
      'type': report.type.name,
      'date': report.date.toIso8601String(),
      'driverName': report.driverName,
      'vehicleId': report.vehicleId,
      'trailerId': report.trailerId,
      'odometer': report.odometer,
      'condition': report.condition.name,
      'signature': report.signature,
      'notes': report.notes,
      'items': report.items
          .map((item) => {
                'name': item.item.name,
                'isDefective': item.isDefective,
                'defectDescription': item.defectDescription,
              })
          .toList(),
    };

    final result = await dvirBackend.create(data);
    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
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

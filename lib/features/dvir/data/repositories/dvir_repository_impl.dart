import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../datasources/dvir_remote_data_source.dart';

class DvirRepositoryImpl implements DvirRepository {
  final DvirRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DvirRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<DvirReport>>> getDvirReports(
      String vehicleId) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    return executeWithHandling(() async {
      final rawReports = await remoteDataSource.getDvirReports(vehicleId);

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

      return reports;
    });
  }

  @override
  Future<Either<Failure, bool>> submitDvirReport(DvirReport report) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    return executeWithHandling(() async {
      await remoteDataSource.submitDvirReport(report);
      return true;
    });
  }

  InspectionType _parseInspectionType(String? type) {
    if (type == InspectionType.postTrip.name) return InspectionType.postTrip;
    return InspectionType.preTrip;
  }

  VehicleCondition _parseVehicleCondition(String? condition) {
    if (condition == VehicleCondition.needsRepair.name)
      return VehicleCondition.needsRepair;
    if (condition == VehicleCondition.unsafe.name)
      return VehicleCondition.unsafe;
    return VehicleCondition.safe;
  }

  InspectionItem _parseInspectionItem(String? name) {
    return InspectionItem.values.firstWhere(
      (item) => item.name == name,
      orElse: () => InspectionItem.engine,
    );
  }
}

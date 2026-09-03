import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exception.dart';
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
  Future<Either<Failure, List<DvirReport>>> getDvirReports(String vehicleId) async {
    if (networkInfo.isConnected) {
      try {
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
            }).toList() ?? [],
          );
        }).toList();

        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server Error'));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> submitDvirReport(DvirReport report) async {
    if (networkInfo.isConnected) {
      try {
        await remoteDataSource.submitDvirReport(report);
        return const Right(true); // Assuming returning true for success instead of null
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server Error'));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      // In a real app, we would save to local DB here and sync later
      return const Left(NetworkFailure());
    }
  }

  InspectionType _parseInspectionType(String? type) {
    if (type == InspectionType.postTrip.name) return InspectionType.postTrip;
    return InspectionType.preTrip;
  }

  VehicleCondition _parseVehicleCondition(String? condition) {
    if (condition == VehicleCondition.needsRepair.name) return VehicleCondition.needsRepair;
    if (condition == VehicleCondition.unsafe.name) return VehicleCondition.unsafe;
    return VehicleCondition.safe;
  }

  InspectionItem _parseInspectionItem(String? name) {
    return InspectionItem.values.firstWhere(
      (item) => item.name == name,
      orElse: () => InspectionItem.engine,
    );
  }
}

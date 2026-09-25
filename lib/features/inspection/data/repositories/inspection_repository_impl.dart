import 'package:fpdart/fpdart.dart';

import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/inspection_data.dart';
import '../../domain/repositories/inspection_repository.dart';

class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionBackend inspectionBackend;
  final NetworkInfo networkInfo;

  InspectionRepositoryImpl({
    required this.inspectionBackend,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<InspectionDayData>>> getInspectionReport(
      int driverId) async {
    if (networkInfo.isConnected) {
      try {
        final result = await inspectionBackend.getLegacyInspectionReport(driverId);
        
        return result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (rawData) {
            final days = rawData.map((json) {
              return InspectionDayData(
                date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
                drivingHours: (json['drivingHours'] as num?)?.toDouble() ?? 0.0,
                onDutyHours: (json['onDutyHours'] as num?)?.toDouble() ?? 0.0,
                offDutyHours: (json['offDutyHours'] as num?)?.toDouble() ?? 0.0,
                sleeperHours: (json['sleeperHours'] as num?)?.toDouble() ?? 0.0,
                isCertified: json['isCertified'] ?? false,
              );
            }).toList();

            return Right(days);
          }
        );
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> exportInspectionData(
      int driverId, TransferMethod method, String? email, bool isErods) async {
    if (networkInfo.isConnected) {
      try {
        final result = await inspectionBackend.exportLegacyInspectionData(
            driverId, method.name, email, isErods);
        return result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (_) => const Right(true),
        );
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

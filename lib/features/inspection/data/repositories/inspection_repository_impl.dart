import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/inspection_data.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../datasources/inspection_remote_data_source.dart';

class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  InspectionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<InspectionDayData>>> getInspectionReport(int driverId) async {
    if (networkInfo.isConnected) {
      try {
        final rawData = await remoteDataSource.getInspectionReport(driverId);
        
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
  Future<Either<Failure, bool>> exportInspectionData(int driverId, TransferMethod method, String? email, bool isErods) async {
    if (networkInfo.isConnected) {
      try {
        await remoteDataSource.exportInspectionData(driverId, method, email, isErods);
        return const Right(true);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server Error'));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

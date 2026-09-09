import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../../../core/utils/logger.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;

  ReportsRepositoryImpl(this._apiClient, this._endpoints);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getComprehensiveEldReport(
      int driverId,
      {Map<String, String>? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) {
        if (period.containsKey('from'))
          queryParams['period[from]'] = period['from'];
        if (period.containsKey('to')) queryParams['period[to]'] = period['to'];
      }

      final response = await _apiClient.get(
        _endpoints.eldComprehensiveReport(driverId),
        queryParameters: queryParams,
      );

      if (response.data['status'] == true) {
        return Right(response.data['data'] as Map<String, dynamic>);
      } else {
        return Left(ServerFailure(
            message: response.data['message'] ??
                'Failed to get comprehensive report'));
      }
    } catch (e) {
      AppLogger.error('Error fetching comprehensive ELD report', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getHosReport(int driverId,
      {Map<String, String>? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) {
        if (period.containsKey('from')) queryParams['from'] = period['from'];
        if (period.containsKey('to')) queryParams['to'] = period['to'];
      }

      final response = await _apiClient.get(
        _endpoints.eldHosReport(driverId),
        queryParameters: queryParams,
      );

      if (response.data['status'] == true) {
        return Right(response.data['data'] as Map<String, dynamic>);
      } else {
        return Left(ServerFailure(
            message: response.data['message'] ?? 'Failed to get HOS report'));
      }
    } catch (e) {
      AppLogger.error('Error fetching HOS report', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportEldReport(int driverId, String format,
      {Map<String, String>? period}) async {
    try {
      final body = <String, dynamic>{
        'format': format,
      };
      if (period != null) {
        body['period'] = period;
      }

      final response = await _apiClient.post(
        _endpoints.eldExportReport(driverId),
        data: body,
      );

      if (response.data['status'] == true) {
        return Right(response.data['data']['download_url'] as String);
      } else {
        return Left(ServerFailure(
            message:
                response.data['message'] ?? 'Failed to export ELD report'));
      }
    } catch (e) {
      AppLogger.error('Error exporting ELD report', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportInspection(int driverId, String format,
      {Map<String, String>? period}) async {
    try {
      final queryParams = <String, dynamic>{
        'format': format,
      };
      if (period != null) {
        if (period.containsKey('from'))
          queryParams['period[from]'] = period['from'];
        if (period.containsKey('to')) queryParams['period[to]'] = period['to'];
      }

      final response = await _apiClient.get(
        _endpoints.inspectionExport(driverId),
        queryParameters: queryParams,
      );

      if (response.data['status'] == true) {
        return Right(response.data['data']['download_url'] as String);
      } else {
        return Left(ServerFailure(
            message: response.data['message'] ??
                'Failed to export inspection data'));
      }
    } catch (e) {
      AppLogger.error('Error exporting inspection', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // --- Standard Traccar Reports ---

  Future<Either<Failure, List<dynamic>>> _getStandardReport(
      String endpoint, List<int> deviceIds, String from, String to) async {
    try {
      final queryParams = <String, dynamic>{
        'deviceId': deviceIds,
        'from': from,
        'to': to,
      };

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
      );

      return Right(response.data as List<dynamic>);
    } catch (e) {
      AppLogger.error('Error fetching standard report: $endpoint', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getSummaryReport(
      List<int> deviceIds, String from, String to) {
    return _getStandardReport(_endpoints.reportSummary, deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getTripsReport(
      List<int> deviceIds, String from, String to) {
    return _getStandardReport(_endpoints.reportTrips, deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getStopsReport(
      List<int> deviceIds, String from, String to) {
    return _getStandardReport(_endpoints.reportStops, deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getRouteReport(
      List<int> deviceIds, String from, String to) {
    return _getStandardReport(_endpoints.reportRoute, deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getEventsReport(
      List<int> deviceIds, String from, String to) {
    return _getStandardReport(_endpoints.reportEvents, deviceIds, from, to);
  }

  @override
  Future<Either<Failure, String?>> exportStandardReport(
      String reportType, List<int> deviceIds, String from, String to) async {
    try {
      final endpoint = '/api/reports/$reportType';
      // Traccar uses specific Accept header for Excel download
      final queryParams = <String, dynamic>{
        'deviceId': deviceIds,
        'from': from,
        'to': to,
      };

      final tempDir = await getTemporaryDirectory();
      final savePath =
          '${tempDir.path}/traccar_report_${reportType}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final downloadedPath = await _apiClient.downloadFile(
        endpoint,
        savePath,
        queryParameters: queryParams,
      );

      return Right(downloadedPath);
    } catch (e) {
      AppLogger.error('Error exporting standard report', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

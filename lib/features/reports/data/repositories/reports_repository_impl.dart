import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../backend/http/api_client.dart';
import '../../../../backend/http/eld_endpoints.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepositoryImpl(this._apiClient, [dynamic _]);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getComprehensiveEldReport(
      int driverId,
      {Map<String, String>? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) {
        if (period.containsKey('from')) {
          queryParams['period[from]'] = period['from'];
        }
        if (period.containsKey('to')) queryParams['period[to]'] = period['to'];
      }

      final result = await _apiClient.get<Map<String, dynamic>>(
        EldEndpoints.dailyReport(driverId),
        queryParameters: queryParams,
      );

      return await result.fold(
        (l) => Left(ServerFailure(message: l.l10nKey)),
        (apiResponse) => Right(apiResponse.data ?? {}),
      );
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

      final result = await _apiClient.get<Map<String, dynamic>>(
        EldEndpoints.dailyReport(driverId), // Map to daily report for now
        queryParameters: queryParams,
      );

      return await result.fold(
        (l) => Left(ServerFailure(message: l.l10nKey)),
        (apiResponse) => Right(apiResponse.data ?? {}),
      );
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

      final result = await _apiClient.post<Map<String, dynamic>>(
        EldEndpoints.generateReport, // Using generateReport
        data: body,
      );

      return await result.fold(
        (l) => Left(ServerFailure(message: l.l10nKey)),
        (apiResponse) {
          final data = apiResponse.data;
          if (data != null && data['download_url'] != null) {
            return Right(data['download_url'] as String);
          }
          return const Left(ServerFailure(message: 'Download URL not found'));
        },
      );
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
        if (period.containsKey('from')) {
          queryParams['period[from]'] = period['from'];
        }
        if (period.containsKey('to')) queryParams['period[to]'] = period['to'];
      }

      final result = await _apiClient.get<Map<String, dynamic>>(
        EldEndpoints.inspectionHtmlReport(driverId), // Map to inspection HTML report
        queryParameters: queryParams,
      );

      return await result.fold(
        (l) => Left(ServerFailure(message: l.l10nKey)),
        (apiResponse) {
          final data = apiResponse.data;
          if (data != null && data['download_url'] != null) {
            return Right(data['download_url'] as String);
          }
          return const Left(ServerFailure(message: 'Download URL not found'));
        },
      );
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

      final result = await _apiClient.get<List<dynamic>>(
        endpoint,
        queryParameters: queryParams,
      );

      return await result.fold(
        (l) => Left(ServerFailure(message: l.l10nKey)),
        (apiResponse) => Right(apiResponse.data ?? []),
      );
    } catch (e) {
      AppLogger.error('Error fetching standard report: $endpoint', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getSummaryReport(
      List<int> deviceIds, String from, String to) async {
    return await _getStandardReport('/reports/summary', deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getTripsReport(
      List<int> deviceIds, String from, String to) async {
    return await _getStandardReport('/reports/trips', deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getStopsReport(
      List<int> deviceIds, String from, String to) async {
    return await _getStandardReport('/reports/stops', deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getRouteReport(
      List<int> deviceIds, String from, String to) async {
    return await _getStandardReport('/reports/route', deviceIds, from, to);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getEventsReport(
      List<int> deviceIds, String from, String to) async {
    return await _getStandardReport('/reports/events', deviceIds, from, to);
  }

  @override
  Future<Either<Failure, String?>> exportStandardReport(
      String reportType, List<int> deviceIds, String from, String to) async {
    try {
      final endpoint = '/api/reports/$reportType';
      final queryParams = <String, dynamic>{
        'deviceId': deviceIds,
        'from': from,
        'to': to,
      };

      final downloadResult = await _apiClient.download(
        endpoint,
        queryParameters: queryParams,
        headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
      );

      return await downloadResult.fold(
        (l) => Left(ServerFailure(message: l.l10nKey)),
        (bytes) async {
          final tempDir = await getTemporaryDirectory();
          final savePath =
              '${tempDir.path}/traccar_report_${reportType}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          return Right(savePath);
        },
      );
    } catch (e) {
      AppLogger.error('Error exporting standard report', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

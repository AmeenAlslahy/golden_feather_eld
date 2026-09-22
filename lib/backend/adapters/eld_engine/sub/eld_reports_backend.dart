import 'dart:typed_data';

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/reports_backend.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [ReportsBackend].
class EldReportsBackend implements ReportsBackend {
  final ApiClient _apiClient;

  const EldReportsBackend(this._apiClient);

  @override
  Future<Result<Uint8List>> getCsv(DriverId driverId) async {
    final res = await _apiClient.get<Uint8List>(
      EldEndpoints.csvReport(driverId.value),
    );
    return res.mapValue((r) => r.data ?? Uint8List(0));
  }

  @override
  Future<Result<RawJson>> getDaily({
    required DriverId driverId,
    DateTime? date,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyReport(driverId.value),
      queryParameters: date != null ? {'date': date.toIso8601String().split('T').first} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getExecutive({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('EldReportsBackend.getExecutive — Phase 2');

  @override
  Future<Result<String>> getHtml({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('EldReportsBackend.getHtml — Phase 2');

  @override
  Future<Result<Uint8List>> getPdf(DriverId driverId) =>
      throw UnimplementedError('EldReportsBackend.getPdf — Phase 2');

  @override
  Future<Result<RawJson>> getWeekly({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('EldReportsBackend.getWeekly — Phase 2');

  @override
  Future<Result<String>> getXml({
    required DriverId driverId,
    DateTime? date,
    String lang = 'ar',
  }) =>
      throw UnimplementedError('EldReportsBackend.getXml — Phase 2');

  @override
  Future<Result<RawJson>> generate({
    required DriverId driverId,
    required ReportFormat format,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? lang,
  }) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.generateReport,
      data: {
        'driverId': driverId.value,
        'format': format.name,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
        if (lang != null) 'lang': lang,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<Uint8List>> downloadLegacyReport(
      String endpoint, Map<String, dynamic>? queryParameters) async {
    final response = await _apiClient.get<Uint8List>(
      endpoint,
      queryParameters: queryParameters,
    );
    return response.map((res) {
      if (res.isSuccess && res.data != null) {
        return res.data!;
      }
      throw Exception(res.message ?? 'Failed to download report');
    });
  }
}

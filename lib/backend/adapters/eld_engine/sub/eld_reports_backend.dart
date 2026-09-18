// ignore_for_file: unused_field, unused_import

import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/reports_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [ReportsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldReportsBackend implements ReportsBackend {
  final ApiClient _apiClient;

  const EldReportsBackend(this._apiClient);

  @override
  Future<Result<Uint8List>> getCsv(DriverId driverId) =>
      throw UnimplementedError('EldReportsBackend.getCsv — Phase 2');

  @override
  Future<Result<RawJson>> getDaily({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('EldReportsBackend.getDaily — Phase 2');

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
  }) =>
      throw UnimplementedError('EldReportsBackend.generate — Phase 2');
}

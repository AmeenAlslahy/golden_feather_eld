import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/reports_backend.dart';

/// In-memory mock for [ReportsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockReportsBackend implements ReportsBackend {
  const MockReportsBackend();

  @override
  Future<Result<Uint8List>> getCsv(DriverId driverId) =>
      throw UnimplementedError('MockReportsBackend.getCsv — Phase 2');

  @override
  Future<Result<RawJson>> getDaily({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('MockReportsBackend.getDaily — Phase 2');

  @override
  Future<Result<RawJson>> getExecutive({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('MockReportsBackend.getExecutive — Phase 2');

  @override
  Future<Result<String>> getHtml({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('MockReportsBackend.getHtml — Phase 2');

  @override
  Future<Result<Uint8List>> getPdf(DriverId driverId) =>
      throw UnimplementedError('MockReportsBackend.getPdf — Phase 2');

  @override
  Future<Result<RawJson>> getWeekly({
    required DriverId driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('MockReportsBackend.getWeekly — Phase 2');

  @override
  Future<Result<String>> getXml({
    required DriverId driverId,
    DateTime? date,
    String lang = 'ar',
  }) =>
      throw UnimplementedError('MockReportsBackend.getXml — Phase 2');

  @override
  Future<Result<RawJson>> generate({
    required DriverId driverId,
    required ReportFormat format,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? lang,
  }) =>
      throw UnimplementedError('MockReportsBackend.generate — Phase 2');

  @override
  Future<Result<Uint8List>> downloadLegacyReport(
      String endpoint, Map<String, dynamic>? queryParameters) async {
    return ok(Uint8List(0));
  }
}

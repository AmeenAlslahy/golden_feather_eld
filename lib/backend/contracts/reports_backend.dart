import 'dart:typed_data';

import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'contract_enums.dart';
import 'raw_json.dart';

abstract interface class ReportsBackend {
  /// GET /eld/reports/{driverId}/csv
  Future<Result<Uint8List>> getCsv(DriverId driverId);

  /// GET /eld/reports/{driverId}/daily
  Future<Result<RawJson>> getDaily({
    required DriverId driverId,
    DateTime? date,
  });

  /// GET /eld/reports/{driverId}/executive
  Future<Result<RawJson>> getExecutive({
    required DriverId driverId,
    DateTime? date,
  });

  /// GET /eld/reports/{driverId}/html
  Future<Result<String>> getHtml({
    required DriverId driverId,
    DateTime? date,
  });

  /// GET /eld/reports/{driverId}/pdf
  Future<Result<Uint8List>> getPdf(DriverId driverId);

  /// GET /eld/reports/{driverId}/weekly
  Future<Result<RawJson>> getWeekly({
    required DriverId driverId,
    DateTime? date,
  });

  /// GET /eld/reports/{driverId}/xml
  Future<Result<String>> getXml({
    required DriverId driverId,
    DateTime? date,
    String lang = 'ar',
  });

  /// POST /eld/reports/generate
  Future<Result<RawJson>> generate({
    required DriverId driverId,
    required ReportFormat format,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? lang,
  });
}

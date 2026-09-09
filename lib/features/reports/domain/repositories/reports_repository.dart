import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';

abstract class ReportsRepository {
  // ELD specific reports
  Future<Either<Failure, Map<String, dynamic>>> getComprehensiveEldReport(
      int driverId,
      {Map<String, String>? period});
  Future<Either<Failure, Map<String, dynamic>>> getHosReport(int driverId,
      {Map<String, String>? period});
  Future<Either<Failure, String>> exportEldReport(int driverId, String format,
      {Map<String, String>? period});
  Future<Either<Failure, String>> exportInspection(int driverId, String format,
      {Map<String, String>? period});

  // Standard Traccar reports
  Future<Either<Failure, List<dynamic>>> getSummaryReport(
      List<int> deviceIds, String from, String to);
  Future<Either<Failure, List<dynamic>>> getTripsReport(
      List<int> deviceIds, String from, String to);
  Future<Either<Failure, List<dynamic>>> getStopsReport(
      List<int> deviceIds, String from, String to);
  Future<Either<Failure, List<dynamic>>> getRouteReport(
      List<int> deviceIds, String from, String to);
  Future<Either<Failure, List<dynamic>>> getEventsReport(
      List<int> deviceIds, String from, String to);
  Future<Either<Failure, String?>> exportStandardReport(
      String reportType, List<int> deviceIds, String from, String to);
}

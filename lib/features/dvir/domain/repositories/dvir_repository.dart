import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/dvir_report.dart';

/// واجهة مستودع DVIR
abstract class DvirRepository {
  /// جلب قائمة تقارير DVIR
  Future<Either<Failure, List<DvirReport>>> getDvirs();

  /// إنشاء تقرير DVIR جديد
  Future<Either<Failure, bool>> createDvir(DvirReport report);

  /// جلب تفاصيل تقرير محدد
  Future<Either<Failure, DvirReport>> getDvirDetail(String id);

  /// جلب DTC Codes من ECM
  Future<Either<Failure, List<String>>> getDtcCodes();
}

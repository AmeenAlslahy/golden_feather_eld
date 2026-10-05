import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class DvirBackend {
  /// GET /eld/dvir
  // TODO(P2): replace with List<DvirReport>
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  });

  /// POST /eld/dvir
  Future<Result<void>> create(RawJson report);

  /// GET /eld/dvir/{id}
  Future<Result<RawJson>> getById(DvirId dvirId);



  /// POST /eld/dvir/{id}/review
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
  });

  /// GET /eld/dvir/catalog
  Future<Result<RawJson>> getDefectsCatalog();

  /// GET /eld/dvir/pre-trip/{uniqueId}
  Future<Result<RawJson>> getPreviousDvir(String uniqueId);

  /// GET /eld/dvir/defects/{id} — تفاصيل العيب وسجل الإصلاحات والاعتمادات
  Future<Result<RawJson>> getDefectDetails(int defectId);

  /// GET /eld/dvir/defects/device/{uniqueId} — العيوب النشطة لمركبة
  Future<Result<RawJson>> getVehicleDefects(String uniqueId);

}

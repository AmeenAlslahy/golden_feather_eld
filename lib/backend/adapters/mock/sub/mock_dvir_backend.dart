import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/dvir_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [DvirBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockDvirBackend implements DvirBackend {
  const MockDvirBackend();

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    return ok({'reports': []});
  }

  @override
  Future<Result<void>> create(RawJson report) async {
    return ok(null);
  }

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) =>
      throw UnimplementedError('MockDvirBackend.getById — Phase 2');



  @override
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
  }) =>
      throw UnimplementedError('MockDvirBackend.review — Phase 2');

  @override
  Future<Result<RawJson>> getDefectsCatalog() async => ok(<String, dynamic>{
        'items': [
          {'code': 'BRAKES_SERVICE', 'name': 'Service brakes', 'nameAr': 'مكابح الخدمة', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': true},
          {'code': 'PARKING_BRAKE', 'name': 'Parking brake', 'nameAr': 'مكبح الوقوف', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': true},
          {'code': 'STEERING', 'name': 'Steering mechanism', 'nameAr': 'آلية التوجيه', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': true},
          {'code': 'LIGHTS', 'name': 'Lighting devices and reflectors', 'nameAr': 'الإضاءة والعاكسات', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': false},
          {'code': 'TIRES', 'name': 'Tires', 'nameAr': 'الإطارات', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': true},
          {'code': 'HORN', 'name': 'Horn', 'nameAr': 'البوق', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': false},
          {'code': 'WIPERS', 'name': 'Windshield wipers', 'nameAr': 'مساحات الزجاج', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': false},
          {'code': 'MIRRORS', 'name': 'Rear vision mirrors', 'nameAr': 'المرايا', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': false},
          {'code': 'COUPLING', 'name': 'Coupling devices', 'nameAr': 'أجهزة الربط', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': true},
          {'code': 'WHEELS_RIMS', 'name': 'Wheels and rims', 'nameAr': 'العجلات والجنوط', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': true},
          {'code': 'EMERGENCY_EQUIPMENT', 'name': 'Emergency equipment', 'nameAr': 'معدات الطوارئ', 'category': 'REGULATORY_MINIMUM', 'statutoryMandatory': true, 'criticalSafety': false},
        ],
      });

  @override
  Future<Result<RawJson>> getPreviousDvir(String uniqueId) async =>
      // Live shape when the vehicle has no DVIR yet (2026-09-25).
      ok(<String, dynamic>{'message': 'No Records', 'hasPreviousDvir': false});
}

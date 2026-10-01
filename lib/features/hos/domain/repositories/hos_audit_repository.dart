import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

abstract class HosAuditRepository {
  Future<void> logViolation(HosViolation violation);
  Future<List<HosViolation>> getViolations();
}

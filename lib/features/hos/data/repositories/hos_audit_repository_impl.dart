import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/hos_audit_repository.dart';

class HosAuditRepositoryImpl implements HosAuditRepository {
  final Box<String> _auditBox;

  HosAuditRepositoryImpl(this._auditBox);

  @override
  Future<void> logViolation(HosViolation violation) async {
    final dateStr = violation.timestamp.toIso8601String().substring(0, 10);
    final all = await getViolations();
    
    for (final v in all) {
      final vDateStr = v.timestamp.toIso8601String().substring(0, 10);
      if (v.type == violation.type && vDateStr == dateStr) {
        return; // Already logged for this day
      }
    }
    
    final jsonStr = jsonEncode(violation.toJson());
    final key = '${dateStr}_${violation.type.name}';
    await _auditBox.put(key, jsonStr);
  }

  @override
  Future<List<HosViolation>> getViolations() async {
    final results = <HosViolation>[];
    for (final key in _auditBox.keys) {
      final jsonStr = _auditBox.get(key);
      if (jsonStr == null) continue;
      try {
        final map = jsonDecode(jsonStr);
        final type = HosViolationType.values.firstWhere((e) => e.name == map['type']);
        final level = ViolationLevel.values.firstWhere((e) => e.name == map['level']);
        results.add(HosViolation(
          type: type,
          level: level,
          message: map['message'],
          timestamp: DateTime.parse(map['timestamp']),
          details: map['details'],
        ));
      } catch (e, st) {
        // الصف الفاسد لا يُسقط بقية سجل المخالفات — لكنه يبقى مرئياً
        // للتشخيص بدل الابتلاع الصامت (سجل تدقيق قانوني).
        AppLogger.warning(
          'HosAuditRepositoryImpl: skipping unreadable audit row "$key"',
          e,
          st,
        );
      }
    }
    return results;
  }
}

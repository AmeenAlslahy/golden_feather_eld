import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/utils/logger.dart';

import '../../domain/repositories/hos_audit_repository.dart';

class HosAuditRepositoryImpl implements HosAuditRepository {
  final Box<String> _auditBox;

  HosAuditRepositoryImpl(this._auditBox);

  /// بادئة مفاتيح المخالفات.
  ///
  /// الشكل: `${yyyy-MM-dd}_${violationType}`
  static const String _keyPrefix = '';

  @override
  Future<void> logViolation(HosViolation violation) async {
    final dateStr = violation.timestamp.toIso8601String().substring(0, 10);
    final key = '$_keyPrefix${dateStr}_${violation.type.name}';

    // المفتاح نفسه يمثّل (النوع + اليوم)، فوجود المفتاح كافٍ للكشف عن
    // التكرار. كان الفحص يقرأ **كل** صفوف صندوق التدقيق ويفكّ JSON كلها
    // عند كل مخالفة وكل نبضة/دقيقة — عمل متكرر بلا فائدة.
    if (_auditBox.containsKey(key)) return;

    await _auditBox.put(key, jsonEncode(violation.toJson()));
  }

  @override
  Future<List<HosViolation>> getViolations() async {
    final results = <HosViolation>[];
    var skippedRows = 0;

    for (final key in _auditBox.keys) {
      if (key is! String) continue; // مفتاح غير نصي
      final jsonStr = _auditBox.get(key);
      if (jsonStr == null || jsonStr.isEmpty) continue;
      if (!key.startsWith(_keyPrefix) || !key.contains('_')) {
        skippedRows++;
        continue;
      }

      try {
        final decoded = jsonDecode(jsonStr);

        // 🛡️ حاجز النوع: الصف يجب أن يكون **كائناً**.
        //
        // بدون هذا كان jsonDecode لقائمة سجلات السجلات اليومية يُرجع List،
        // ثم `map['type']` يفهرس ListBase بمفتاح نصي فيرمي
        // "type 'String' is not a subtype of type 'int' of 'index'" —
        // ويتعطّل سجل المخالفات القانوني بالكامل. الآن الصف الغريب
        // يُتخطّى ولا يُسقط بقية السجل.
        if (decoded is! Map<String, dynamic>) {
          skippedRows++;
          AppLogger.warning(
            'HosAuditRepositoryImpl: audit row "$key" is not an object; skipped',
          );
          continue;
        }

        final typeName = decoded['type'];
        final levelName = decoded['level'];
        final timestampRaw = decoded['timestamp'];

        final type = HosViolationType.values
            .where((e) => e.name == typeName)
            .firstOrNull;
        final level = ViolationLevel.values
            .where((e) => e.name == levelName)
            .firstOrNull;

        if (type == null || level == null || timestampRaw is! String) {
          skippedRows++;
          AppLogger.warning(
            'HosAuditRepositoryImpl: audit row "$key" has unknown enum/fields; skipped',
          );
          continue;
        }

        final parsed = DateTime.tryParse(timestampRaw);
        if (parsed == null) {
          skippedRows++;
          AppLogger.warning(
            'HosAuditRepositoryImpl: audit row "$key" has unparsable timestamp; skipped',
          );
          continue;
        }

        final details = decoded['details'];
        results.add(
          HosViolation(
            type: type,
            level: level,
            message: decoded['message'] is String
                ? decoded['message'] as String
                : '',
            timestamp: parsed,
            details: details is Map<String, dynamic> ? details : null,
          ),
        );
      } catch (e, st) {
        // الصف الفاسد لا يُسقط بقية سجل المخالفات — لكنه يبقى مرئياً
        // للتشخيص بدل الابتلاع الصامت (سجل تدقيق قانوني).
        skippedRows++;
        AppLogger.warning(
          'HosAuditRepositoryImpl: skipping unreadable audit row "$key"',
          e,
          st,
        );
      }
    }

    if (skippedRows > 0) {
      AppLogger.warning(
        'HosAuditRepositoryImpl: $skippedRows audit row(s) skipped as '
        'unreadable or foreign to this box',
      );
    }
    return results;
  }
}

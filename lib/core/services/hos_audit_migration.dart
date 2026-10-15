import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_constants.dart';
import '../utils/logger.dart';

/// ترحيل صندوق مخالفات HOS خارج صندوق سجلات السجلات اليومية.
///
/// **السبب:** كان `HosAuditRepositoryImpl` و`LogLocalDataSource` يتشاركان
/// صندوق `audit_box` بتنسيقين مختلفين:
///
/// | | المفتاح | القيمة |
/// |---|---|---|
/// | سجلات السجلات | `2026-10-07` | **قائمة** JSON `[ {...}, {...} ]` |
/// | مخالفات HOS | `2026-10-07_dailyDrivingExceeded` | **كائن** JSON `{...}` |
///
/// عند قراءة المخالفات كان `jsonDecode` يُرجع `List`، ثم `map['type']`
/// يفهرس `ListBase` بمفتاح نصي فيرمي
/// `type 'String' is not a subtype of type 'int' of 'index'`.
///
/// فالمخالفات لم تُكتب ولم تُقرأ إطلاقاً، و`logViolation` (الذي يعتمد على
/// قراءة القائمة لمنع التكرار) كان يفشل في كل مرة.
///
/// **سلامة الترحيل:** التمييز لا يعتمد على arbitrariness — نتأكد أن
/// الصف **كائن** يحوي مفاتيح المخالفة الثلاثة. صفوف السجلات قوائم، فلا
/// يمكن أن تُطابق. الحذف من الصندوق القديم لا يقع إلا بعد نجاح الكتابة
/// في الجديد، فالأسوأ في أسوأ الحالات تكرار الصف لا فقدانه.
class HosAuditBoxMigration {
  HosAuditBoxMigration({
    required this.legacyBox,
    required this.targetBox,
    this.dryRun = false,
  });

  final Box<String> legacyBox;
  final Box<String> targetBox;

  /// true = فحص فقط بلا كتابة (مفيد للاختبار والتشخيص).
  final bool dryRun;

  /// مفاتيح المخالفة الثلاثة التي تميّز صف مخالفة عن أي صف آخر.
  static const List<String> _violationFields = ['type', 'level', 'timestamp'];

  Future<MigrationReport> run() async {
    var migrated = 0;
    var skipped = 0;
    var malformed = 0;
    final migratedKeys = <String>[];

    for (final key in legacyBox.keys) {
      if (key is! String) continue;
      final raw = legacyBox.get(key);
      if (raw == null || raw.isEmpty) continue;

      // ⛔ لا نلمس صفوف سجلات السجلات (قوائم JSON بمفتاح تاريخ).
      if (!isHosViolationRow(key, raw)) {
        skipped++;
        continue;
      }

      if (targetBox.containsKey(key)) {
        // سبق ترحيله في تشغيل سابق — نتخطاه ولا نكتب مرتين.
        migrated++;
        migratedKeys.add(key);
        continue;
      }

      if (!dryRun) {
        try {
          await targetBox.put(key, raw);
        } catch (e) {
          AppLogger.warning('HOS audit migration: write failed for "$key": $e');
          malformed++;
          continue;
        }
        // الحذف بعد نجاح الكتابة فقط.
        try {
          await legacyBox.delete(key);
        } catch (e) {
          AppLogger.warning(
              'HOS audit migration: delete failed for "$key": $e');
        }
      }
      migrated++;
      migratedKeys.add(key);
    }

    final report = MigrationReport(
      migrated: migrated,
      skippedLogRows: skipped,
      malformed: malformed,
      keys: migratedKeys,
      dryRun: dryRun,
    );
    if (!dryRun) {
      AppLogger.info(
          'HOS audit migration complete: ${report.migrated} violation(s) '
          'moved, ${report.skippedLogRows} log row(s) left untouched');
    }
    return report;
  }

  /// هل هذا الصف مخالفة HOS (لا صف سجل يومي)؟
  ///
  /// معرّفان **مستقلان** حتى لا نخطئ:
  ///   1. المفتاح يتبع `${dateStr}_${violationType}`
  ///   2. القيمة كائن يحمل type/level/timestamp
  static bool isHosViolationRow(String key, String raw) {
    if (!key.contains('_')) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false; // List ⇒ سجل يومي
      return _violationFields.every(decoded.containsKey);
    } catch (_) {
      return false;
    }
  }
}

class MigrationReport {
  const MigrationReport({
    required this.migrated,
    required this.skippedLogRows,
    required this.malformed,
    required this.keys,
    required this.dryRun,
  });

  final int migrated;
  final int skippedLogRows;
  final int malformed;
  final List<String> keys;
  final bool dryRun;

  @override
  String toString() =>
      'MigrationReport(migrated: $migrated, skippedLogRows: $skippedLogRows, '
      'malformed: $malformed, dryRun: $dryRun)';
}

/// يفتح صندوق المخالفات الجديد ويُشغّل الترحيل.
///
/// يُستدعى من `LocalDatabaseService.init()` بعد فتح `audit_box` القديم.
Future<void> openHosAuditBoxAndMigrate() async {
  try {
    final target = await Hive.openBox<String>(StorageConstants.hosAuditBox);
    if (!Hive.isBoxOpen(StorageConstants.auditBox)) {
      AppLogger.info(
          'HOS audit migration skipped: legacy audit_box not open yet');
      return;
    }
    final legacy = Hive.box<String>(StorageConstants.auditBox);
    await HosAuditBoxMigration(
      legacyBox: legacy,
      targetBox: target,
    ).run();
  } catch (e, st) {
    // الترحيل لا يجوز أن يمنع الإقلاع. الفشل يعني بقاء السلوك السابق
    // (المخالفات لا تُقرأ) — أخطر من التوقف، فنُسجّله ونكمل.
    AppLogger.error('HOS audit migration failed', e, st);
  }
}
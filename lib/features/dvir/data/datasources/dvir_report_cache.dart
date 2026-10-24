import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/logger.dart';

/// A previous-DVIR cache answer.
///
/// `report == null` means the server explicitly answered "no previous DVIR"
/// for this vehicle. Returning `null` from [DvirReportCache.readPrevious]
/// means the answer is *unknown* (no cache, or the cached row was unusable).
class CachedPreviousDvir {
  final Map<String, dynamic>? report;

  const CachedPreviousDvir(this.report);
}

/// Durable cache for DVIR records returned by the backend.
///
/// Rules:
/// - Only server-shaped records with a positive numeric `id` are accepted.
///   `POST /eld/dvir` request bodies are never cache material: they have no
///   `id` and used to poison the read path for the whole vehicle.
/// - Reads are tolerant: one bad row is skipped, the rest still load.
/// - Writes are versioned (`v2`) so a future shape change cannot be silently
///   interpreted as the old one. Legacy keys are migrated once, then deleted.
class DvirReportCache {
  static const _reportsV2Prefix = 'dvir_reports:v2:';
  static const _previousV2Prefix = 'dvir_prev:v2:';
  static const _reportsLegacyPrefix = 'dvir_reports:';
  static const _previousLegacyPrefix = 'dvir_prev:';
  static const _envelopeVersion = 2;

  const DvirReportCache();

  /// Stores [reports] (the raw `data` list from the backend). Invalid rows are
  /// dropped. An empty list is a valid cached answer ("no reports").
  void saveReports(String vehicleId, List<dynamic> reports) {
    _write('$_reportsV2Prefix${vehicleId.trim()}', {
      'version': _envelopeVersion,
      'reports': _sanitizeList(reports),
    });
  }

  /// Returns the cached server records, or `null` when there is no usable
  /// cache for this vehicle. An empty list means "known to be empty".
  List<Map<String, dynamic>>? readReports(String vehicleId) {
    final key = vehicleId.trim();
    final fromV2 = _readReportsV2(key);
    if (fromV2 != null) return fromV2;

    final legacy = _readJson('$_reportsLegacyPrefix$key');
    if (legacy is! List) return null;

    final migrated = _sanitizeList(legacy);
    saveReports(key, migrated);
    _delete('$_reportsLegacyPrefix$key');
    AppLogger.debug(
      'DVIR cache migrated: ${migrated.length} valid record(s) kept.',
    );
    return migrated;
  }

  void savePrevious(String vehicleId, Map<String, dynamic> report) {
    final safe = _sanitize(report);
    if (safe == null) return;
    _write('$_previousV2Prefix${vehicleId.trim()}', {
      'version': _envelopeVersion,
      'report': safe,
    });
  }

  void saveNoPrevious(String vehicleId) {
    _write('$_previousV2Prefix${vehicleId.trim()}', {
      'version': _envelopeVersion,
      'report': null,
    });
  }

  CachedPreviousDvir? readPrevious(String vehicleId) {
    final key = vehicleId.trim();
    final decoded = _readJson('$_previousV2Prefix$key');
    if (decoded is Map) {
      if (decoded['version'] != _envelopeVersion) return null;
      if (!decoded.containsKey('report')) return null;
      final raw = decoded['report'];
      if (raw == null) return const CachedPreviousDvir(null);
      final safe = _sanitize(raw);
      if (safe == null) return null;
      return CachedPreviousDvir(safe);
    }

    final legacy = _readJson('$_previousLegacyPrefix$key');
    final safe = _sanitize(legacy);
    if (safe == null) return null;
    savePrevious(key, safe);
    _delete('$_previousLegacyPrefix$key');
    return CachedPreviousDvir(safe);
  }

  /// Applies a completed/certain §396.13 review to both cached server records
  /// and the cached previous answer, so an offline review does not prompt the
  /// same driver again after a restart.
  void markReviewCompleted({
    required String vehicleId,
    required int dvirId,
    required String reviewerName,
  }) {
    final key = vehicleId.trim();
    final reports = readReports(key);
    if (reports != null) {
      final updated = reports.map((report) {
        if (_numericId(report) != dvirId) return report;
        return {
          ...report,
          'nextDriverReviewed': true,
          'reviewingDriverName': reviewerName,
        };
      }).toList();
      saveReports(key, updated);
    }

    final previous = _readJson('$_previousV2Prefix$key');
    if (previous is Map &&
        previous['version'] == _envelopeVersion &&
        previous['report'] is Map) {
      final report = Map<String, dynamic>.from(previous['report'] as Map);
      if (_numericId(report) == dvirId) {
        report['nextDriverReviewed'] = true;
        report['reviewingDriverName'] = reviewerName;
        savePrevious(key, report);
      }
    }
  }

  List<Map<String, dynamic>>? _readReportsV2(String key) {
    final decoded = _readJson('$_reportsV2Prefix$key');
    if (decoded is List) return _sanitizeList(decoded);
    if (decoded is! Map) return null;
    if (decoded['version'] != _envelopeVersion) return null;
    final reports = decoded['reports'];
    if (reports is! List) return null;
    return _sanitizeList(reports);
  }

  List<Map<String, dynamic>> _sanitizeList(List<dynamic> source) {
    final result = <Map<String, dynamic>>[];
    for (final row in source) {
      final safe = _sanitize(row);
      if (safe != null) result.add(safe);
    }
    return result;
  }

  /// Returns a normalized copy with a numeric positive `id`, or `null` when
  /// the row is not a server report.
  static Map<String, dynamic>? _sanitize(Object? raw) {
    if (raw is! Map) return null;
    final id = _numericId(raw);
    if (id == null || id <= 0) return null;
    try {
      return {...Map<String, dynamic>.from(raw), 'id': id};
    } catch (_) {
      return null;
    }
  }

  static int? _numericId(Map<dynamic, dynamic> raw) {
    final value = raw['id'];
    if (value is num) {
      final id = value.toInt();
      return value == id ? id : null;
    }
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Box<String>? _box() {
    if (!Hive.isBoxOpen(StorageConstants.dailyLogsCacheBox)) return null;
    return Hive.box<String>(StorageConstants.dailyLogsCacheBox);
  }

  void _write(String key, Map<String, dynamic> value) {
    try {
      _box()?.put(key, jsonEncode(value));
    } catch (error) {
      AppLogger.warning('Failed to write DVIR cache: $error');
    }
  }

  Object? _readJson(String key) {
    try {
      final raw = _box()?.get(key);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (error) {
      AppLogger.warning('Failed to read DVIR cache: $error');
      return null;
    }
  }

  void _delete(String key) {
    try {
      _box()?.delete(key);
    } catch (error) {
      AppLogger.warning('Failed to delete DVIR cache: $error');
    }
  }
}

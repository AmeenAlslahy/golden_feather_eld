import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

abstract class LogLocalDataSource {
  Future<List<LogEvent>> getEvents(DateTime date);
  Future<bool> addEvent(LogEvent event);
  Future<bool> updateEvent(LogEvent event);
  Future<List<DutyPeriod>> getPeriods(DateTime date, [DateTime? referenceNow]);
  Future<bool> savePeriod(DutyPeriod period);
  Future<bool> logAudit(AuditEntry entry);
  Future<List<AuditEntry>> getAuditEntries(DateTime date);

  /// SRS 7.16: أحدث الأحداث عبر كل الأيام (قراءة فقط).
  Future<List<AuditEntry>> getRecentAuditEntries({int limit = 100});

  /// SRS 6.8 — read-only snapshot of the last server answers so the Logs
  /// list and a day's events stay available without a connection.
  Future<void> cacheDailyLogs(
    int driverId,
    List<Map<String, dynamic>> logsJson,
  );
  Future<List<Map<String, dynamic>>?> getCachedDailyLogs(int driverId);
  Future<void> cacheLogEvents(
    DailyLogId logId,
    List<Map<String, dynamic>> eventsJson,
  );
  Future<List<Map<String, dynamic>>?> getCachedLogEvents(DailyLogId logId);
  Future<void> saveSignature(DailyLogId logId, String base64Signature);
  Future<String?> getSignature(DailyLogId logId);
  Future<void> saveDraftSignature(DailyLogId logId, String pointsJson);
  Future<String?> getDraftSignature(DailyLogId logId);
  Future<void> deleteDraftSignature(DailyLogId logId);

  /// Cache and retrieve daily forms offline (SRS 6.8).
  Future<void> cacheDailyForm(DailyLogId logId, Map<String, dynamic> formJson);
  Future<Map<String, dynamic>?> getCachedDailyForm(DailyLogId logId);
  Future<void> markCachedDailyLogFormComplete({
    required int driverId,
    required DailyLogId logId,
    required bool isComplete,
  });

  /// P0 2B-1 — مالك سجل مخزن لـ logId عبر مفاتيح `logs:{driverId}` فقط.
  /// يُرجع المعرف عند انفراده، وإلا null (غياب/غموض/تعدد) — لا يُستنتج
  /// أي مالك من الجلسة الحالية هنا أبداً. قراءة خالصة بلا آثار.
  Future<int?> ownerOfCachedLog(int logId);

  /// P0 عزل السائقين — مسح فترات الخدمة المخزنة محلياً.
  ///
  /// الـ periods مخزَّنة بمفاتيح أيام فقط (بلا مالك)، فلا يمكن نسبتها
  /// لسائق بعينه. عند تبديل هوية السائق تُمسح بدل تمريرها للسائق الجديد:
  /// هي كاش مشتق من الأحداث (والأحداث نفسها في طابور المزامنة محفوظة
  /// الملكية)، واللوحة الأونلاين تُرتَّب من الخادم بعد تسجيل الدخول.
  Future<void> clearPeriods();
}

class LogLocalDataSourceImpl implements LogLocalDataSource {
  Box<String> get _eventsBox => Hive.box<String>(StorageConstants.eventsBox);
  Box<String> get _periodsBox => Hive.box<String>(StorageConstants.periodsBox);
  Box<String> get _auditBox => Hive.box<String>(StorageConstants.auditBox);
  Box<String> get _cacheBox =>
      Hive.box<String>(StorageConstants.dailyLogsCacheBox);

  // --- SRS 6.8 offline snapshot ---

  @override
  Future<void> cacheDailyLogs(
    int driverId,
    List<Map<String, dynamic>> logsJson,
  ) async {
    try {
      await _cacheBox.put('logs:$driverId', jsonEncode(logsJson));
    } catch (e) {
      AppLogger.warning('Daily-logs cache write skipped: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedDailyLogs(int driverId) async =>
      _readCachedList('logs:$driverId');

  @override
  Future<void> cacheLogEvents(
    DailyLogId logId,
    List<Map<String, dynamic>> eventsJson,
  ) async {
    try {
      await _cacheBox.put('events:${logId.value}', jsonEncode(eventsJson));
    } catch (e) {
      AppLogger.warning('Log-events cache write skipped: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedLogEvents(
    DailyLogId logId,
  ) async => _readCachedList('events:${logId.value}');

  @override
  Future<void> saveSignature(DailyLogId logId, String base64Signature) async {
    try {
      await _cacheBox.put('sig:${logId.value}', base64Signature);
    } catch (e) {
      AppLogger.warning('Signature write skipped: $e');
    }
  }

  @override
  Future<String?> getSignature(DailyLogId logId) async {
    return _cacheBox.get('sig:${logId.value}');
  }

  @override
  Future<void> saveDraftSignature(DailyLogId logId, String pointsJson) async {
    try {
      await _cacheBox.put('sig_draft:${logId.value}', pointsJson);
    } catch (e) {
      AppLogger.warning('Signature draft write skipped: $e');
    }
  }

  @override
  Future<String?> getDraftSignature(DailyLogId logId) async {
    return _cacheBox.get('sig_draft:${logId.value}');
  }

  @override
  Future<void> deleteDraftSignature(DailyLogId logId) async {
    try {
      await _cacheBox.delete('sig_draft:${logId.value}');
    } catch (e) {
      AppLogger.warning('Signature draft delete skipped: $e');
    }
  }

  @override
  Future<void> cacheDailyForm(
    DailyLogId logId,
    Map<String, dynamic> formJson,
  ) async {
    try {
      await _cacheBox.put('form:${logId.value}', jsonEncode(formJson));
    } catch (e) {
      AppLogger.warning('Form cache write skipped: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedDailyForm(DailyLogId logId) async {
    final raw = _cacheBox.get('form:${logId.value}');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  @override
  Future<void> markCachedDailyLogFormComplete({
    required int driverId,
    required DailyLogId logId,
    required bool isComplete,
  }) async {
    try {
      final key = 'logs:$driverId';
      final logs = _readCachedList(key);
      if (logs == null) return;
      var changed = false;
      final updated = logs.map((log) {
        final id = log['id'];
        final matches = id is num
            ? id.toInt() == logId.value
            : int.tryParse('$id') == logId.value;
        if (matches) {
          changed = true;
          final copy = Map<String, dynamic>.from(log);
          copy['formStatus'] = isComplete ? 'COMPLETED' : 'INCOMPLETE';
          copy['isFormComplete'] = isComplete;
          return copy;
        }
        return log;
      }).toList();

      if (changed) {
        await _cacheBox.put(key, jsonEncode(updated));
      }
    } catch (e) {
      AppLogger.warning('markCachedDailyLogFormComplete skipped: $e');
    }
  }

  @override
  Future<int?> ownerOfCachedLog(int logId) async {
    try {
      final owners = <int>{};
      for (final key in _cacheBox.keys) {
        if (key is! String || !key.startsWith('logs:')) continue;
        final owner = int.tryParse(key.substring('logs:'.length));
        if (owner == null || owner <= 0) continue;
        final entries = _readCachedList(key);
        if (entries == null) continue;
        for (final entry in entries) {
          final id = entry['id'];
          final match = id is num
              ? id.toInt() == logId
              : int.tryParse('$id') == logId;
          if (match) owners.add(owner);
        }
      }
      return owners.length == 1 ? owners.single : null;
    } catch (e) {
      AppLogger.warning('ownerOfCachedLog failed: $e');
      return null;
    }
  }

  List<Map<String, dynamic>>? _readCachedList(String key) {
    final raw = _cacheBox.get(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Helper Methods ---

  Future<bool> _saveToBox(
    Box<String> box,
    Map<String, dynamic> data,
    String timestampKey,
    String entityName,
  ) async {
    try {
      final dateStr = AppDateUtils.extractDateStr(
        data[timestampKey] as String?,
      );
      final currentList = _getListFromBox(box, dateStr);
      currentList.add(data);

      await box.put(dateStr, jsonEncode(currentList));
      return true;
    } catch (e) {
      AppLogger.error('Failed to save $entityName', e);
      throw CacheException('Failed to save $entityName: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getFromBox(
    Box<String> box,
    DateTime date,
    String entityName,
  ) async {
    try {
      final dateStr = AppDateUtils.formatDate(date);
      return _getListFromBox(box, dateStr);
    } catch (e) {
      AppLogger.error('Failed to get $entityName', e);
      throw CacheException('Failed to get $entityName: $e');
    }
  }

  List<Map<String, dynamic>> _getListFromBox(Box<String> box, String dateStr) {
    final data = box.get(dateStr);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Implementations ---

  @override
  Future<List<LogEvent>> getEvents(DateTime date) async {
    final data = await _getFromBox(_eventsBox, date, 'events');
    final events = <LogEvent>[];
    for (final e in data) {
      final id = e['id'] as String?;
      final startTimeStr = e['startTime'] as String?;
      if (id == null ||
          id.isEmpty ||
          startTimeStr == null ||
          startTimeStr.isEmpty) {
        AppLogger.warning(
          'LogLocalDataSource.getEvents: skipped malformed event',
        );
        continue;
      }
      try {
        events.add(
          LogEvent(
            id: id,
            status: e['status'] as String,
            startTime: DateTime.parse(startTimeStr),
            duration: Duration(seconds: _readDurationSeconds(e)),
            location: e['location'] as String? ?? 'Unknown',
            odometer: (e['odometer'] as num?)?.toDouble(),
            engineHours: (e['engineHours'] as num?)?.toDouble(),
          ),
        );
      } catch (ex, st) {
        AppLogger.warning(
          'LogLocalDataSource.getEvents: failed to parse event $id',
          ex,
          st,
        );
      }
    }
    return events;
  }

  /// يقبل 'durationSeconds' (الصيغة المحلية) أو 'duration' (صيغة الخادم).
  int _readDurationSeconds(Map<String, dynamic> e) {
    final v = (e['durationSeconds'] as num?) ?? (e['duration'] as num?);
    return v?.toInt() ?? 0;
  }

  Map<String, dynamic> _eventMap(LogEvent event) {
    return {
      'id': event.id,
      'status': event.status,
      'startTime': event.startTime.toIso8601String(),
      'durationSeconds': event.duration.inSeconds,
      'location': event.location,
      'odometer': event.odometer,
      'engineHours': event.engineHours,
      'timestamp': event.startTime.toIso8601String(),
    };
  }

  @override
  Future<bool> addEvent(LogEvent event) async {
    return _saveToBox(_eventsBox, _eventMap(event), 'timestamp', 'event');
  }

  @override
  Future<bool> updateEvent(LogEvent event) async {
    final map = _eventMap(event);
    try {
      final dateStr = AppDateUtils.formatDate(event.startTime);
      final currentList = _getListFromBox(_eventsBox, dateStr);
      final idx = currentList.indexWhere((e) => e['id'] == event.id);
      if (idx >= 0) {
        currentList[idx] = map;
      } else {
        currentList.add(map);
      }
      await _eventsBox.put(dateStr, jsonEncode(currentList));
      return true;
    } catch (e) {
      AppLogger.error('Failed to update event', e);
      throw CacheException('Failed to update event: $e');
    }
  }

  @override
  Future<List<DutyPeriod>> getPeriods(
    DateTime date, [
    DateTime? referenceNow,
  ]) async {
    final data = await _getFromBox(_periodsBox, date, 'periods');
    final now = referenceNow;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final fallbackEnd =
        (now != null &&
            now.year == date.year &&
            now.month == date.month &&
            now.day == date.day)
        ? now
        : endOfDay;

    return data
        .map(
          (e) => DutyPeriod(
            status: e['status'] as String? ?? 'off_duty',
            startTime: DateTime.parse(e['startTime'] as String),
            endTime: e['endTime'] != null
                ? DateTime.parse(e['endTime'] as String)
                : fallbackEnd,
            startOdometer: (e['startOdometer'] as num?)?.toDouble(),
            endOdometer: (e['endOdometer'] as num?)?.toDouble(),
            startLat: (e['startLat'] as num?)?.toDouble(),
            startLon: (e['startLon'] as num?)?.toDouble(),
            endLat: (e['endLat'] as num?)?.toDouble(),
            endLon: (e['endLon'] as num?)?.toDouble(),
          ),
        )
        .toList();
  }

  @override
  Future<bool> savePeriod(DutyPeriod period) async {
    final map = {
      'status': period.status,
      'startTime': period.startTime.toIso8601String(),
      'endTime': period.endTime.toIso8601String(),
      'startOdometer': period.startOdometer,
      'endOdometer': period.endOdometer,
      'startLat': period.startLat,
      'startLon': period.startLon,
      'endLat': period.endLat,
      'endLon': period.endLon,
    };
    return _saveToBox(_periodsBox, map, 'startTime', 'period');
  }

  @override
  Future<void> clearPeriods() async {
    try {
      await _periodsBox.clear();
    } catch (e) {
      AppLogger.warning('Failed to clear periods box: $e');
    }
  }

  @override
  Future<bool> logAudit(AuditEntry entry) async {
    return _saveToBox(_auditBox, entry.toMap(), 'timestamp', 'audit');
  }

  @override
  Future<List<AuditEntry>> getAuditEntries(DateTime date) async {
    final data = await _getFromBox(_auditBox, date, 'audit');
    return data.map((e) => AuditEntry.fromMap(e)).toList();
  }

  @override
  Future<List<AuditEntry>> getRecentAuditEntries({int limit = 100}) async {
    // الصندوق مجزأ بمفاتيح الأيام؛ نجمع كل الأيام ثم نرتب تنازلياً.
    final all = <AuditEntry>[];
    for (final key in _auditBox.keys) {
      final raw = _auditBox.get(key);
      if (raw == null) continue;
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        for (final item in list) {
          all.add(AuditEntry.fromMap(item));
        }
      } catch (_) {
        // سجل تالف: يُتخطى ولا يُحذف (SRS 1.3 — لا حذف من سجل التدقيق).
      }
    }
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }
}

final logLocalDataSourceProvider = Provider<LogLocalDataSource>((ref) {
  return LogLocalDataSourceImpl();
});

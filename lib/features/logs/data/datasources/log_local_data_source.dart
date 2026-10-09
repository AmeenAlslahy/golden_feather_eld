import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/logger.dart';
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
  Future<List<DutyPeriod>> getPeriods(DateTime date);
  Future<bool> savePeriod(DutyPeriod period);
  Future<bool> logAudit(AuditEntry entry);
  Future<List<AuditEntry>> getAuditEntries(DateTime date);

  /// SRS 7.16: أحدث الأحداث عبر كل الأيام (قراءة فقط).
  Future<List<AuditEntry>> getRecentAuditEntries({int limit = 100});

  /// SRS 6.8 — read-only snapshot of the last server answers so the Logs
  /// list and a day's events stay available without a connection.
  Future<void> cacheDailyLogs(int driverId, List<Map<String, dynamic>> logsJson);
  Future<List<Map<String, dynamic>>?> getCachedDailyLogs(int driverId);
  Future<void> cacheLogEvents(DailyLogId logId, List<Map<String, dynamic>> eventsJson);
  Future<List<Map<String, dynamic>>?> getCachedLogEvents(DailyLogId logId);
  Future<void> saveSignature(DailyLogId logId, String base64Signature);
  Future<String?> getSignature(DailyLogId logId);
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
      int driverId, List<Map<String, dynamic>> logsJson) async {
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
      DailyLogId logId, List<Map<String, dynamic>> eventsJson) async {
    try {
      await _cacheBox.put('events:${logId.value}', jsonEncode(eventsJson));
    } catch (e) {
      AppLogger.warning('Log-events cache write skipped: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedLogEvents(
          DailyLogId logId) async =>
      _readCachedList('events:${logId.value}');

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
      final dateStr =
          AppDateUtils.extractDateStr(data[timestampKey] as String?);
      final currentList = _getListFromBox(box, dateStr);
      currentList.add(data);

      await box.put(dateStr, jsonEncode(currentList));
      return true;
    } catch (e) {
      AppLogger.error('Failed to save $entityName', e);
      throw Exception('Failed to save $entityName: $e');
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
      throw Exception('Failed to get $entityName: $e');
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
      if (id == null || id.isEmpty || startTimeStr == null || startTimeStr.isEmpty) {
        AppLogger.warning('LogLocalDataSource.getEvents: skipped malformed event');
        continue;
      }
      try {
        events.add(LogEvent(
          id: id,
          status: e['status'] as String,
          startTime: DateTime.parse(startTimeStr),
          duration: Duration(seconds: _readDurationSeconds(e)),
          location: e['location'] as String? ?? 'Unknown',
          odometer: (e['odometer'] as num?)?.toDouble(),
          engineHours: (e['engineHours'] as num?)?.toDouble(),
        ));
      } catch (ex, st) {
        AppLogger.warning('LogLocalDataSource.getEvents: failed to parse event $id', ex, st);
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
      throw Exception('Failed to update event: $e');
    }
  }

  @override
  Future<List<DutyPeriod>> getPeriods(DateTime date) async {
    final data = await _getFromBox(_periodsBox, date, 'periods');
    return data
        .map((e) => DutyPeriod(
              status: e['status'] as String? ?? 'off_duty',
              startTime: DateTime.parse(e['startTime'] as String),
              endTime: e['endTime'] != null
                  ? DateTime.parse(e['endTime'] as String)
                  : DateTime.now(),
              startOdometer: (e['startOdometer'] as num?)?.toDouble(),
              endOdometer: (e['endOdometer'] as num?)?.toDouble(),
              startLat: (e['startLat'] as num?)?.toDouble(),
              startLon: (e['startLon'] as num?)?.toDouble(),
              endLat: (e['endLat'] as num?)?.toDouble(),
              endLon: (e['endLon'] as num?)?.toDouble(),
            ))
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

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/daily_log.dart';

abstract class LogLocalDataSource {
  Future<List<LogEvent>> getEvents(DateTime date);
  Future<bool> addEvent(LogEvent event);
  Future<bool> updateEvent(LogEvent event);
  Future<List<DutyPeriod>> getPeriods(DateTime date);
  Future<bool> savePeriod(DutyPeriod period);
  Future<bool> logAudit(AuditEntry entry);
  Future<List<AuditEntry>> getAuditEntries(DateTime date);
}

class LogLocalDataSourceImpl implements LogLocalDataSource {
  Box<String> get _eventsBox => Hive.box<String>(StorageConstants.eventsBox);
  Box<String> get _periodsBox => Hive.box<String>(StorageConstants.periodsBox);
  Box<String> get _auditBox => Hive.box<String>(StorageConstants.auditBox);

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
      final validItems = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          validItems.add(e);
        }
      }
      return validItems;
    } catch (_) {
      // Backup corrupted data to prevent silent overwriting
      box.put('${dateStr}_corrupted_${DateTime.now().millisecondsSinceEpoch}', data);
      return [];
    }
  }

  // --- Implementations ---

  @override
  Future<List<LogEvent>> getEvents(DateTime date) async {
    final data = await _getFromBox(_eventsBox, date, 'events');
    return data
        .map((e) => LogEvent(
              id: e['id'] as String? ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              status: e['status'] as String,
              statusArabic:
                  e['statusArabic'] as String? ?? e['status'] as String,
              startTime: DateTime.parse(e['startTime'] as String),
              duration: Duration(seconds: e['durationSeconds'] as int? ?? 0),
              location: e['location'] as String? ?? 'Unknown',
              odometer: (e['odometer'] as num?)?.toDouble(),
              engineHours: (e['engineHours'] as num?)?.toDouble(),
            ))
        .toList();
  }

  @override
  Future<bool> addEvent(LogEvent event) async {
    final map = {
      'id': event.id,
      'status': event.status,
      'statusArabic': event.statusArabic,
      'startTime': event.startTime.toIso8601String(),
      'durationSeconds': event.duration.inSeconds,
      'location': event.location,
      'odometer': event.odometer,
      'engineHours': event.engineHours,
      'timestamp': event.startTime.toIso8601String(),
    };
    return _saveToBox(_eventsBox, map, 'timestamp', 'event');
  }

  @override
  Future<bool> updateEvent(LogEvent event) async {
    try {
      final dateStr = AppDateUtils.formatDate(event.startTime);
      final currentList = _getListFromBox(_eventsBox, dateStr);
      
      final index = currentList.indexWhere((e) => e['id'] == event.id);
      final map = {
        'id': event.id,
        'status': event.status,
        'statusArabic': event.statusArabic,
        'startTime': event.startTime.toIso8601String(),
        'durationSeconds': event.duration.inSeconds,
        'location': event.location,
        'odometer': event.odometer,
        'engineHours': event.engineHours,
        'timestamp': event.startTime.toIso8601String(),
      };
      
      if (index != -1) {
        currentList[index] = map;
      } else {
        currentList.add(map);
      }
      
      await _eventsBox.put(dateStr, jsonEncode(currentList));
      return true;
    } catch (e) {
      AppLogger.error('Failed to update event', e);
      return false;
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
}

final logLocalDataSourceProvider = Provider<LogLocalDataSource>((ref) {
  return LogLocalDataSourceImpl();
});

import 'package:golden_feather_eld/core/engine/hos_models.dart';
import '../../../../core/services/local_database_service.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/audit_entry.dart';
import '../../../../core/engine/tracking/duty_status_tracker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final LocalDatabaseService _localDb;

  LogLocalDataSourceImpl(this._localDb);

  @override
  Future<List<LogEvent>> getEvents(DateTime date) async {
    final result = await _localDb.getEventsByDate(date);
    return result.match(
      (failure) => throw Exception(failure.message),
      (data) {
        return data.map((e) => LogEvent(
          id: e['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
          status: e['status'] as String,
          statusArabic: e['statusArabic'] as String? ?? e['status'] as String,
          startTime: DateTime.parse(e['startTime'] as String),
          duration: Duration(seconds: e['durationSeconds'] as int? ?? 0),
          location: e['location'] as String? ?? 'Unknown',
          odometer: (e['odometer'] as num?)?.toDouble(),
          engineHours: (e['engineHours'] as num?)?.toDouble(),
        )).toList();
      }
    );
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
    final result = await _localDb.saveEvent(map);
    return result.isRight();
  }

  @override
  Future<bool> updateEvent(LogEvent event) async {
    // Basic implementation since we just append right now.
    // In a real local DB with Hive, you'd find the item and update it. 
    return addEvent(event); 
  }

  @override
  Future<List<DutyPeriod>> getPeriods(DateTime date) async {
    final result = await _localDb.getPeriodsByDate(date);
    return result.match(
      (failure) => throw Exception(failure.message),
      (data) {
        return data.map((e) => DutyPeriod(
          status: e['status'] as String? ?? 'off_duty',
          startTime: DateTime.parse(e['startTime'] as String),
          endTime: e['endTime'] != null ? DateTime.parse(e['endTime'] as String) : DateTime.now(),
          startOdometer: (e['startOdometer'] as num?)?.toDouble(),
          endOdometer: (e['endOdometer'] as num?)?.toDouble(),
          startLat: (e['startLat'] as num?)?.toDouble(),
          startLon: (e['startLon'] as num?)?.toDouble(),
          endLat: (e['endLat'] as num?)?.toDouble(),
          endLon: (e['endLon'] as num?)?.toDouble(),
        )).toList();
      }
    );
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
    final result = await _localDb.savePeriod(map);
    return result.isRight();
  }

  @override
  Future<bool> logAudit(AuditEntry entry) async {
    final result = await _localDb.saveAudit(entry.toMap());
    return result.isRight();
  }

  @override
  Future<List<AuditEntry>> getAuditEntries(DateTime date) async {
    final result = await _localDb.getAudit(date);
    return result.match(
      (failure) => throw Exception(failure.message),
      (data) {
        return data.map((e) => AuditEntry.fromMap(e)).toList();
      }
    );
  }
}

final logLocalDataSourceProvider = Provider<LogLocalDataSource>((ref) {
  final localDb = ref.watch(localDatabaseServiceProvider);
  return LogLocalDataSourceImpl(localDb);
});

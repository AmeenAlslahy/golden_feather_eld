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
import '../models/log_model.dart';
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

  /// يحدّث حدثاً واحداً في كاش الخادم `events:<logId>` وفي صندوق الأحداث
  /// المحلي، مع إزالة نسخته القديمة من أي يوم سابق إذا تغيّر وقت البدء.
  /// يُستخدم بعد تأكيد `PUT` حتى لا يمحو `GET` فاشل التعديل المؤكد.
  Future<void> upsertCachedLogEvent(
    DailyLogId logId,
    Map<String, dynamic> eventJson,
  );

  /// يحدّث حالة مزامنة حدث واحد في لقطة `events:<logId>` وفي صندوق
  /// الأحداث المحلي معاً. [status] = `none` يمسح العلامة بعد تأكيد الخادم.
  Future<void> setCachedEventSyncStatus({
    required DailyLogId logId,
    required String eventId,
    required EventSyncStatus status,
  });
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

  /// يعلّم النموذج المخزّن أنه محفوظ محلياً بانتظار المزامنة، لا مكتملاً
  /// من الخادم. يستخدمه مسار الأوفلاين بعد حفظ البيانات والطابور.
  Future<void> markCachedDailyLogFormPendingSync({
    required int driverId,
    required DailyLogId logId,
  });

  /// تحديث حالة المزامنة المخزّنة لسجل واحد بشكل ذري.
  ///
  /// [formStatus] و/أو [certificationStatus] قيم wire صريحة
  /// (`PENDING_SYNC`, `SYNC_FAILED`, `CERTIFIED`, `COMPLETED` ...).
  /// تُستخدم من مسار المزامنة بعد استجابة الخادم الفعلية: لا اكتمال
  /// مفترض، ولا حذف لبيانات المستخدم.
  Future<void> markCachedDailyLogSyncStatus({
    required int driverId,
    required DailyLogId logId,
    String? formStatus,
    String? certificationStatus,
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
      final key = 'logs:$driverId';
      // لا تمسح حالة محلية لم يؤكدها الخادم بعد (PENDING_SYNC) أو رفضها
      // نهائياً (SYNC_FAILED) عند كل تحديث للقائمة. الخادم لا يعرف حالة
      // الطابور المحلي، فاستبدال الصف كان يمحوها فور إعادة فتح الشاشة.
      final previous = _readCachedList(key);
      final localById = <String, Map<String, String>>{};
      if (previous != null) {
        for (final row in previous) {
          final id = row['id']?.toString();
          if (id == null || id.isEmpty) continue;
          final form = row['formStatus']?.toString().trim().toUpperCase();
          final cert = row['certificationStatus']
              ?.toString()
              .trim()
              .toUpperCase();
          final keepForm = form != null && _localFormStates.contains(form);
          final keepCert = cert != null && _localCertStates.contains(cert);
          if (keepForm || keepCert) {
            localById[id] = {
              if (keepForm) 'form': form,
              if (keepCert) 'cert': cert,
            };
          }
        }
      }

      final merged = logsJson.map((log) {
        final id = log['id']?.toString();
        final local = id == null ? null : localById[id];
        if (local == null) return Map<String, dynamic>.from(log);
        final copy = Map<String, dynamic>.from(log);
        final serverForm = copy['formStatus']?.toString().trim().toUpperCase();
        if (local['form'] != null && !_serverConfirmsForm(serverForm)) {
          copy['formStatus'] = local['form'];
          copy['isFormComplete'] = false;
        }
        final serverCert = copy['certificationStatus']
            ?.toString()
            .trim()
            .toUpperCase();
        if (local['cert'] != null && !_serverConfirmsCert(serverCert)) {
          copy['certificationStatus'] = local['cert'];
          copy['isCertified'] = false;
        }
        return copy;
      }).toList();

      await _cacheBox.put(key, jsonEncode(merged));
    } catch (e) {
      AppLogger.warning('Daily-logs cache write skipped: $e');
    }
  }

  static const Set<String> _localFormStates = {
    'PENDING_SYNC',
    'SAVED_UNCONFIRMED',
    'SYNC_FAILED',
    'SYNC_FAILED_PERMANENTLY',
  };

  static const Set<String> _localCertStates = {
    'PENDING_SYNC',
    'SYNC_FAILED',
    'SYNC_FAILED_PERMANENTLY',
  };

  static bool _serverConfirmsForm(String? status) =>
      status == 'COMPLETED' || status == 'COMPLETE';

  static bool _serverConfirmsCert(String? status) => status == 'CERTIFIED';

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
  Future<void> upsertCachedLogEvent(
    DailyLogId logId,
    Map<String, dynamic> eventJson,
  ) async {
    final id = eventJson['id']?.toString();
    if (id == null || id.isEmpty) return;
    // المعرّف يُخزّن نصياً في الصندوق المحلي؛ نوحّده حتى لو جاء رقمياً من
    // استجابة الخادم، فلا يفشل القارئ بعد إعادة فتح التطبيق.
    final normalized = <String, dynamic>{...eventJson, 'id': id};

    try {
      // 1) لقطة الخادم: استبدال/إضافة الحدث نفسه فقط، بلا مسح بقية اليوم.
      final key = 'events:${logId.value}';
      final cached = _readCachedList(key) ?? <Map<String, dynamic>>[];
      final cachedIndex = cached.indexWhere((e) => e['id']?.toString() == id);
      if (cachedIndex >= 0) {
        cached[cachedIndex] = normalized;
      } else {
        cached.add(normalized);
      }
      await _cacheBox.put(key, jsonEncode(cached));

      // 2) صندوق الأحداث المحلي: قد يكون الحدث في يوم سابق بعد تعديل
      // وقت البدء؛ نزيله من كل الأيام ثم نضيفه ليومه الجديد.
      await _removeLocalEventById(id);

      final startRaw = normalized['startTime']?.toString();
      final start = startRaw == null ? null : DateTime.tryParse(startRaw);
      if (start != null) {
        final dateStr = AppDateUtils.formatDate(start);
        final list = _getListFromBox(_eventsBox, dateStr);
        list.add(normalized);
        await _eventsBox.put(dateStr, jsonEncode(list));
      }
    } catch (e) {
      // فشل الكاش لا يحوّل تعديلاً مؤكداً إلى فشل. يُسجّل ويُترك للـGET
      // التالي؛ لكن لا نمحو شيئاً من بيانات المستخدم.
      AppLogger.warning('Event cache upsert skipped: $e');
    }
  }

  Future<void> _removeLocalEventById(String id) async {
    for (final rawKey in _eventsBox.keys.toList()) {
      final dateKey = rawKey.toString();
      final list = _getListFromBox(_eventsBox, dateKey);
      final before = list.length;
      list.removeWhere((e) => e['id']?.toString() == id);
      if (list.length != before) {
        await _eventsBox.put(dateKey, jsonEncode(list));
      }
    }
  }

  @override
  Future<void> setCachedEventSyncStatus({
    required DailyLogId logId,
    required String eventId,
    required EventSyncStatus status,
  }) async {
    final wire = LogEventModel.syncStatusToWire(status);
    try {
      final key = 'events:${logId.value}';
      final cached = _readCachedList(key);
      if (cached != null) {
        var changed = false;
        final updated = cached.map((row) {
          if (row['id']?.toString() != eventId) return row;
          changed = true;
          return _withSyncStatus(row, wire);
        }).toList();
        if (changed) await _cacheBox.put(key, jsonEncode(updated));
      }

      // صندوق الأحداث قد يحمل الحدث تحت يوم آخر إذا تغيّر وقت البدء؛
      // نحدّث كل النسخ المطابقة بدل الافتراض أن اليوم الحالي فقط.
      for (final rawKey in _eventsBox.keys.toList()) {
        final dateKey = rawKey.toString();
        final list = _getListFromBox(_eventsBox, dateKey);
        var changed = false;
        final updated = list.map((row) {
          if (row['id']?.toString() != eventId) return row;
          changed = true;
          return _withSyncStatus(row, wire);
        }).toList();
        if (changed) {
          await _eventsBox.put(dateKey, jsonEncode(updated));
        }
      }
    } catch (e) {
      AppLogger.warning('setCachedEventSyncStatus skipped: $e');
    }
  }

  static Map<String, dynamic> _withSyncStatus(
    Map<String, dynamic> row,
    String? wire,
  ) {
    final copy = Map<String, dynamic>.from(row);
    if (wire == null) {
      copy.remove('syncStatus');
    } else {
      copy['syncStatus'] = wire;
    }
    return copy;
  }

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
  }) {
    return markCachedDailyLogSyncStatus(
      driverId: driverId,
      logId: logId,
      formStatus: isComplete ? 'COMPLETED' : 'INCOMPLETE',
    );
  }

  @override
  Future<void> markCachedDailyLogFormPendingSync({
    required int driverId,
    required DailyLogId logId,
  }) {
    return markCachedDailyLogSyncStatus(
      driverId: driverId,
      logId: logId,
      formStatus: 'PENDING_SYNC',
    );
  }

  @override
  Future<void> markCachedDailyLogSyncStatus({
    required int driverId,
    required DailyLogId logId,
    String? formStatus,
    String? certificationStatus,
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
        if (!matches) return log;
        changed = true;
        final copy = Map<String, dynamic>.from(log);
        if (formStatus != null) {
          final upper = formStatus.trim().toUpperCase();
          copy['formStatus'] = upper;
          copy['isFormComplete'] = _serverConfirmsForm(upper);
        }
        if (certificationStatus != null) {
          final upper = certificationStatus.trim().toUpperCase();
          copy['certificationStatus'] = upper;
          copy['isCertified'] = _serverConfirmsCert(upper);
        }
        return copy;
      }).toList();

      if (changed) {
        await _cacheBox.put(key, jsonEncode(updated));
      }
    } catch (e) {
      AppLogger.warning('markCachedDailyLogSyncStatus skipped: $e');
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
      try {
        // نفس محلّل الواجهة: يقبل الصيغة المحلية وصيغة الخادم
        // (`timeRange`) ويوحّد الحالة والتوقيت و`syncStatus`.
        events.add(LogEventModel.fromJson(e));
      } catch (ex, st) {
        AppLogger.warning(
          'LogLocalDataSource.getEvents: failed to parse event '
          '${e['id']}',
          ex,
          st,
        );
      }
    }
    return events;
  }

  Map<String, dynamic> _eventMap(LogEvent event) {
    final syncStatus = LogEventModel.syncStatusToWire(event.syncStatus);
    return {
      'id': event.id,
      'status': event.status,
      'startTime': event.startTime.toIso8601String(),
      'durationSeconds': event.duration.inSeconds,
      'location': event.location,
      'odometer': event.odometer,
      'engineHours': event.engineHours,
      'timestamp': event.startTime.toIso8601String(),
      if (syncStatus != null) 'syncStatus': syncStatus,
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
      // وقت البدء قد انتقل إلى يوم آخر: إزالة النسخة القديمة أولاً تمنع
      // ظهور الحدث مرتين في يومين مختلفين بعد إعادة فتح التطبيق.
      await _removeLocalEventById(event.id);
      final dateStr = AppDateUtils.formatDate(event.startTime);
      final currentList = _getListFromBox(_eventsBox, dateStr);
      currentList.add(map);
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

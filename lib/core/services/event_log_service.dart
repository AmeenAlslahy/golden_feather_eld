import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../time/time_authority.dart';
import '../time/time_authority_provider.dart';

/// نموذج حدث مسجل
class LoggedEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const LoggedEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };

  factory LoggedEvent.fromJson(Map<String, dynamic> json) => LoggedEvent(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        data: Map<String, dynamic>.from(json['data'] ?? {}),
      );
}

/// خدمة سجل الأحداث المحلي
class EventLogService {
  static const String _eventsKey = 'event_logs';
  final TimeAuthority _timeAuthority;
  List<LoggedEvent> _cache = [];

  EventLogService({required TimeAuthority timeAuthority})
      : _timeAuthority = timeAuthority;

  /// تهيئة السجل
  Future<void> init() async {
    await _loadFromStorage();
    AppLogger.info(
        '📋 EventLogService initialized with ${_cache.length} events');
  }

  /// تسجيل حدث
  Future<void> logEvent(String type, Map<String, dynamic> data) async {
    final now = _timeAuthority.nowUtc();
    final event = LoggedEvent(
      // Uuid لا milliseconds: حدثان في نفس الميلي ثانية كانا يتصادمان
      // ويحذف أحدهما الآخر من خرائط القراءة.
      id: const Uuid().v4(),
      type: type,
      timestamp: now,
      data: data,
    );
    _cache.add(event);
    await _saveToStorage();
    AppLogger.info('📝 Event logged: $type');
  }

  /// الحصول على أحداث اليوم
  /// Returns events whose timestamp is on or after UTC midnight of the
  /// current day.
  ///
  /// **Note:** "Today" is currently UTC-based. If a driver's log uses
  /// a different time zone (home terminal), this will need refinement.
  List<LoggedEvent> getTodayEvents() {
    final now = _timeAuthority.nowUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    return _cache.where((e) => !e.timestamp.isBefore(todayStart)).toList();
  }

  /// الحصول على أحداث حسب النوع
  List<LoggedEvent> getEventsByType(String type) {
    return _cache.where((e) => e.type == type).toList();
  }

  /// الحصول على جميع الأحداث
  List<LoggedEvent> get allEvents => List.unmodifiable(_cache);

  /// تحميل من التخزين
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_eventsKey);
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data);
        _cache = list.map((e) => LoggedEvent.fromJson(e)).toList();
      } catch (e) {
        _cache = [];
      }
    }
  }

  /// حفظ للتخزين
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_cache.map((e) => e.toJson()).toList());
    await prefs.setString(_eventsKey, data);
  }

  /// مسح السجل
  Future<void> clear() async {
    _cache.clear();
    await _saveToStorage();
  }
}

/// مزود خدمة سجل الأحداث
final eventLogServiceProvider = Provider<EventLogService>((ref) {
  return EventLogService(timeAuthority: ref.watch(timeAuthorityProvider));
});

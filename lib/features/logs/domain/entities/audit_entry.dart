import 'package:equatable/equatable.dart';

/// سجل تدقيق للتعديلات اليدوية
class AuditEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final String driverId;
  final String? oldStatus;
  final String newStatus;
  final String reason;

  const AuditEntry({
    required this.id,
    required this.timestamp,
    required this.driverId,
    this.oldStatus,
    required this.newStatus,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // ISO string: _saveToBox يستخرج مفتاح اليوم من نص ISO.
      'timestamp': timestamp.toIso8601String(),
      'driverId': driverId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'reason': reason,
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] as String? ?? '',
      timestamp: _readTimestamp(map['timestamp']),
      driverId: map['driverId'] as String? ?? '',
      oldStatus: map['oldStatus'] as String?,
      newStatus: map['newStatus'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
    );
  }

  /// يقبل ISO string (الصيغة الحالية) أو int milliseconds (سجلات قديمة).
  static DateTime _readTimestamp(Object? raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  List<Object?> get props =>
      [id, timestamp, driverId, oldStatus, newStatus, reason];
}

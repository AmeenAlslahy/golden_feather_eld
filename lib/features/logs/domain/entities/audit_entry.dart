import 'package:equatable/equatable.dart';

/// سجل تدقيق للتعديلات اليدوية
///
/// SRS 7.16: كل حدث يحمل الإجراء ونوع الكيان ومعرفه والمستخدم ودوره.
/// الحقول الجديدة اختيارية للتوافق الخلفي مع القيود المخزنة سابقاً.
class AuditEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final String driverId;
  final String? oldStatus;
  final String newStatus;
  final String reason;

  /// اسم الإجراء (مثل edit_event / certify / sign_dvir / review_dvir).
  final String action;

  /// نوع الكيان المتأثر (daily_log / dvir / rules / session / transfer).
  final String? entityType;

  /// معرف الكيان المتأثر.
  final String? entityId;

  /// هوية المستخدم المنفذ (حسب 1.3).
  final String? userName;

  /// دور المستخدم (driver / carrier).
  final String? userRole;

  const AuditEntry({
    required this.id,
    required this.timestamp,
    required this.driverId,
    this.oldStatus,
    required this.newStatus,
    required this.reason,
    this.action = '',
    this.entityType,
    this.entityId,
    this.userName,
    this.userRole,
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
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'userName': userName,
      'userRole': userRole,
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
      action: map['action'] as String? ?? '',
      entityType: map['entityType'] as String?,
      entityId: map['entityId']?.toString(),
      userName: map['userName'] as String?,
      userRole: map['userRole'] as String?,
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
  List<Object?> get props => [
        id,
        timestamp,
        driverId,
        oldStatus,
        newStatus,
        reason,
        action,
        entityType,
        entityId,
        userName,
        userRole,
      ];
}

/// Decision 2 (P1): Reconnect Loop & Hardware Diagnostics.
/// Models for reporting hardware diagnostic events and alerts to the server and offline queue.
library;

class DiagnosticAlertRequest {
  final String alertType;
  final int attemptNumber;
  final DateTime timestamp;
  final String? macAddress;
  final Map<String, dynamic> metadata;

  const DiagnosticAlertRequest({
    required this.alertType,
    required this.attemptNumber,
    required this.timestamp,
    this.macAddress,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'alert_type': alertType,
    'attempt_number': attemptNumber,
    'timestamp': timestamp.toUtc().toIso8601String(),
    if (macAddress != null) 'mac_address': macAddress,
    'metadata': metadata,
  };

  factory DiagnosticAlertRequest.fromJson(Map<String, dynamic> json) =>
      DiagnosticAlertRequest(
        alertType: json['alert_type'] as String? ?? 'unknown',
        attemptNumber: json['attempt_number'] as int? ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now().toUtc(),
        macAddress: json['mac_address'] as String?,
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : const {},
      );
}

class AlertResponse {
  final bool success;
  final String? alertId;
  final String? message;

  const AlertResponse({
    required this.success,
    this.alertId,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    if (alertId != null) 'alert_id': alertId,
    if (message != null) 'message': message,
  };

  factory AlertResponse.fromJson(Map<String, dynamic> json) => AlertResponse(
    success: json['success'] as bool? ?? true,
    alertId: json['alert_id'] as String?,
    message: json['message'] as String?,
  );
}

/// `GET /eld/hardware/readiness` → `PreOperationReadinessResponse`.
///
/// Pre-operation readiness of the paired ELD (SRS 3.3 readiness states).
/// The checklist keys are server-defined (`device_paired`,
/// `connection_active`, `motion_data`, `location_data`, `engine_telemetry`);
/// unknown keys are still shown so a new server check is never hidden.
class HardwareReadiness {
  final bool ready;
  final String? vehicleName;
  final String? eldIdentifier;

  /// Ordered as the server sent them.
  final Map<String, bool> checklist;
  final List<String> rejectionReasons;
  final String? recommendedAction;

  const HardwareReadiness({
    required this.ready,
    this.vehicleName,
    this.eldIdentifier,
    this.checklist = const {},
    this.rejectionReasons = const [],
    this.recommendedAction,
  });
}

/// A non-object body is an error. A missing `ready` is not treated as ready.
HardwareReadiness? parseHardwareReadiness(dynamic data) {
  final root = _asMap(data);
  if (root == null) return null;
  final nested = root['data'];
  if (nested != null && nested is! Map) return null;
  final body = _asMap(nested) ?? root;

  final rawChecklist = body['checklist'];
  if (rawChecklist != null && rawChecklist is! Map) return null;
  final checklist = <String, bool>{};
  if (rawChecklist is Map) {
    for (final entry in rawChecklist.entries) {
      final value = entry.value;
      final flag = value is bool
          ? value
          : value?.toString().trim().toLowerCase() == 'true';
      checklist['${entry.key}'.trim()] = flag;
    }
  }

  final rawReasons = body['rejectionReasons'];
  if (rawReasons != null && rawReasons is! List) return null;
  final reasons = (rawReasons as List? ?? const [])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();

  return HardwareReadiness(
    ready: body['ready'] == true,
    vehicleName: _text(body['vehicleName']),
    eldIdentifier: _text(body['eldIdentifier']),
    checklist: checklist,
    rejectionReasons: reasons,
    recommendedAction: _text(body['recommendedAction']),
  );
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

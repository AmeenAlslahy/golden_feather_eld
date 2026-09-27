/// `GET /eld/daily-logs/{id}/team` — team-driving status of one daily log
/// and the server's statement that the two drivers' HOS records are isolated
/// (SRS 5.8). Read-only; the app never derives isolation locally.
class TeamStatus {
  final int? dailyLogId;
  final String? primaryDriverName;
  final String? coDriverName;
  final bool teamModeActive;

  /// Null when the server did not say (never assumed isolated).
  final bool? hosRecordsIsolated;
  final String? complianceNote;

  const TeamStatus({
    this.dailyLogId,
    this.primaryDriverName,
    this.coDriverName,
    this.teamModeActive = false,
    this.hosRecordsIsolated,
    this.complianceNote,
  });
}

/// A non-object body is an error; `{data:{...}}` envelopes are unwrapped.
TeamStatus? parseTeamStatus(dynamic data) {
  final root = _asMap(data);
  if (root == null) return null;
  final nested = root['data'];
  if (nested != null && nested is! Map) return null;
  final body = _asMap(nested) ?? root;
  final primary = _asMap(body['primaryDriver']);
  final co = _asMap(body['coDriver']);
  final isolated = body['hosRecordsIsolated'];
  return TeamStatus(
    dailyLogId: (body['dailyLogId'] as num?)?.toInt(),
    primaryDriverName: _text(primary?['name']),
    coDriverName: _text(co?['name']),
    teamModeActive: body['teamModeActive'] == true,
    hosRecordsIsolated: isolated is bool ? isolated : null,
    complianceNote: _text(body['complianceNote']),
  );
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null' || text == 'string') return null;
  return text;
}

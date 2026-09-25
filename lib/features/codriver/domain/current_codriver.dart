class CurrentCoDriverRead {
  final int? coDriverId;
  final String? name;
  final bool teamDrivingActive;

  const CurrentCoDriverRead({
    this.coDriverId,
    this.name,
    this.teamDrivingActive = false,
  });

  bool get isLinked => coDriverId != null && coDriverId! > 0;
}

/// A non-object body is an error. `coDriverId` of 0 is an empty link, not a driver.
CurrentCoDriverRead? parseCurrentCoDriver(dynamic data) {
  final root = _asMap(data);
  if (root == null) return null;
  final body = _asMap(root['data']) ?? root;
  final nested = _asMap(body['coDriver']);
  final nestedId = nested == null
      ? null
      : _asInt(nested['coDriverId'] ?? nested['id'] ?? nested['driverId']);
  final bodyId = _asInt(body['coDriverId']);
  final id = nestedId != null && nestedId > 0 ? nestedId : bodyId;
  final team = body['teamDrivingActive'] == true ||
      body['teamMode'] == true ||
      body['teamModeActive'] == true;
  if (id == null || id <= 0) {
    return CurrentCoDriverRead(teamDrivingActive: team);
  }
  final name = nested?['name']?.toString() ?? body['coDriverName']?.toString();
  final trimmed = name?.trim();
  return CurrentCoDriverRead(
    coDriverId: id,
    name: trimmed == null || trimmed.isEmpty ? null : trimmed,
    teamDrivingActive: team,
  );
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

int? _asInt(dynamic raw) {
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}

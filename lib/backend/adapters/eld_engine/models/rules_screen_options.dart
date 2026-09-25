/// Reads dropdown options from the rules-screen payload.
///
/// Server keys are mapped to the field names the screen already uses.
/// Missing or empty lists stay absent. No federal rule is invented here.
Map<String, List<String>> readRulesOptions(Object? raw) {
  if (raw is! Map) return const {};
  const aliases = {
    'availableCycleRules': 'cycleRule',
    'availableCargoTypes': 'cargoType',
    'availableRestarts': 'restart',
    'availableRestBreaks': 'restBreak',
  };
  final result = <String, List<String>>{};
  raw.forEach((key, value) {
    if (value is! List) return;
    final name = aliases[key.toString()] ?? key.toString();
    final items = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (items.isEmpty) return;
    final existing = result[name] ?? <String>[];
    for (final item in items) {
      if (!existing.contains(item)) existing.add(item);
    }
    result[name] = existing;
  });
  return result;
}

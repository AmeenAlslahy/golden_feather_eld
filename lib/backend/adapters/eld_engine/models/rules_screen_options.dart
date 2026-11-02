/// Reads dropdown options from both old and new rules-screen APIs.
///
/// Supports:
/// - Old API keys: availableCycleRules, availableCargoTypes, etc.
/// - New API keys: cycleRules, cargoTypes, restarts, restBreaks.
/// - String options: ["USA_70HR_8DAY"]
/// - Object options: [{"code": "USA_70HR_8DAY"}]
///
/// Maps server keys to existing Flutter screen field names.
///
/// Missing or empty lists stay absent.
/// Duplicate values are removed.
/// No default federal rules are invented.
Map<String, List<String>> readRulesOptions(Object? raw) {
  if (raw is! Map) {
    return <String, List<String>>{};
  }

  const aliases = <String, String>{
    // Old Backend API
    'availableCycleRules': 'cycleRule',
    'availableCargoTypes': 'cargoType',
    'availableRestarts': 'restart',
    'availableRestBreaks': 'restBreak',

    // New Backend API
    'cycleRules': 'cycleRule',
    'cargoTypes': 'cargoType',
    'restarts': 'restart',
    'restBreaks': 'restBreak',

    // Existing Flutter field names
    'cycleRule': 'cycleRule',
    'cargoType': 'cargoType',
    'restart': 'restart',
    'restBreak': 'restBreak',
  };

  final result = <String, List<String>>{};

  raw.forEach((key, value) {
    if (value is! List) return;

    final fieldName = aliases[key.toString()] ?? key.toString();

    final parsedOptions = <String>[];

    for (final item in value) {
      String? optionCode;

      // Old API: String values
      if (item is String) {
        optionCode = item.trim();
      }

      // New API: Object containing "code"
      else if (item is Map) {
        final code = item['code'];

        if (code is String) {
          optionCode = code.trim();
        }
      }

      // Ignore invalid or empty options
      if (optionCode == null || optionCode.isEmpty) {
        continue;
      }

      // Prevent duplicate options
      if (!parsedOptions.contains(optionCode)) {
        parsedOptions.add(optionCode);
      }
    }

    // Do not add empty dropdown lists
    if (parsedOptions.isEmpty) return;

    // Merge options when old and new aliases coexist
    final existingOptions = result.putIfAbsent(
      fieldName,
      () => <String>[],
    );

    for (final option in parsedOptions) {
      if (!existingOptions.contains(option)) {
        existingOptions.add(option);
      }
    }
  });

  return result;
}
import '../../../../core/config/hos_configuration.dart';

/// Application read-projection model for the Rules Screen UI.
/// This is NOT a domain entity. It represents the specific UI requirements
/// and available options for the settings screen.
class RulesScreenModel {
  final String ruleSource;
  final String cycleRule;
  final String cargoType;
  final String restart;
  final String restBreak;
  final bool sixteenHourException;

  /// Options available for dropdowns
  final Map<String, List<String>> options;

  /// Fields that the user is authorized to edit
  final Set<String> editableFields;

  /// Fields that must be rendered as read-only info rows
  final Set<String> readOnlyFields;

  /// Fixed settings dictated by the fleet
  final Map<String, dynamic> fixedSettings;

  /// Authorization notice or generic warning
  final String notice;

  /// The parsed engine limits corresponding to the selected rule
  final HosConfiguration limits;

  const RulesScreenModel({
    required this.ruleSource,
    required this.cycleRule,
    required this.cargoType,
    required this.restart,
    required this.restBreak,
    required this.sixteenHourException,
    required this.options,
    required this.editableFields,
    required this.readOnlyFields,
    required this.fixedSettings,
    required this.notice,
    required this.limits,
  });

  Map<String, dynamic> toJson() {
    return {
      'ruleSource': ruleSource,
      'cycleRule': cycleRule,
      'cargoType': cargoType,
      'restart': restart,
      'restBreak': restBreak,
      'sixteenHourException': sixteenHourException,
      'options': options,
      'editableFields': editableFields.toList(),
      'readOnlyFields': readOnlyFields.toList(),
      'fixedSettings': fixedSettings,
      'notice': notice,
      'limits': limits.toJson(),
    };
  }

  factory RulesScreenModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String, List<String>>{};
    if (rawOptions is Map) {
      for (final entry in rawOptions.entries) {
        if (entry.value is List) {
          options[entry.key.toString()] = (entry.value as List)
              .map((e) => e.toString())
              .toList();
        }
      }
    }

    final rawLimits = json['limits'];
    final limits = rawLimits is Map
        ? HosConfiguration.fromJson(Map<String, dynamic>.from(rawLimits))
        : HosConfiguration.usa70_8();

    return RulesScreenModel(
      ruleSource: json['ruleSource']?.toString() ?? '',
      cycleRule: json['cycleRule']?.toString() ?? '',
      cargoType: json['cargoType']?.toString() ?? '',
      restart: json['restart']?.toString() ?? '',
      restBreak: json['restBreak']?.toString() ?? '',
      sixteenHourException: parseBool(json['sixteenHourException']),
      options: options,
      editableFields:
          (json['editableFields'] as List?)?.map((e) => e.toString()).toSet() ??
          const {},
      readOnlyFields:
          (json['readOnlyFields'] as List?)?.map((e) => e.toString()).toSet() ??
          const {},
      fixedSettings: json['fixedSettings'] is Map
          ? Map<String, dynamic>.from(json['fixedSettings'] as Map)
          : const {},
      notice: json['notice']?.toString() ?? '',
      limits: limits,
    );
  }

  /// الخادم قد يرسل مفاتيح نصية (personalConveyance: "Allowed")
  /// أو الصيغة المنطقية (*Enabled: true) — هذا الفاحص الموحد يقبل الصيغتين.
  bool get isPersonalConveyanceAllowed => _isSettingAllowed(const [
    'personalConveyance',
    'personalConveyanceEnabled',
  ]);

  bool get isYardMoveAllowed =>
      _isSettingAllowed(const ['yardMoves', 'yardMoveEnabled']);

  static const _allowedValues = {
    'allowed',
    'true',
    'yes',
    '1',
    'enabled',
    'on',
    'permitted',
  };

  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final t = value.toString().trim().toLowerCase();
    return _allowedValues.contains(t);
  }

  static const _forbiddenValues = {
    'forbidden',
    'false',
    'no',
    '0',
    'disabled',
    'off',
  };

  bool _isSettingAllowed(List<String> keys) =>
      tryIsSettingAllowed(keys) ?? false;

  /// نتيجة ثلاثية: true مباح، false ممنوع، null غير معروف/غير موجود.
  bool? tryIsSettingAllowed(List<String> keys) {
    for (final key in keys) {
      final v = fixedSettings[key];
      if (v == null) continue;
      if (v is bool) return v;
      final t = v.toString().trim().toLowerCase();
      if (_allowedValues.contains(t)) return true;
      if (_forbiddenValues.contains(t)) return false;
    }
    return null;
  }

  /// أول قيمة نصية معروفة لهذه المفاتيح — تُعرض كما وردت من الخادم
  /// عندما تكون الصيغة غير مصنّفة (لا in allowed ولا forbidden).
  String? firstSettingDisplayText(List<String> keys) {
    for (final key in keys) {
      final v = fixedSettings[key];
      if (v == null) continue;
      final text = v.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}

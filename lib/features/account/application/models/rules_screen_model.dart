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

  /// الخادم قد يرسل مفاتيح نصية (personalConveyance: "Allowed")
  /// أو الصيغة المنطقية (*Enabled: true) — هذا الفاحص الموحد يقبل الصيغتين.
  bool get isPersonalConveyanceAllowed => _isSettingAllowed(const [
        'personalConveyance',
        'personalConveyanceEnabled',
      ]);

  bool get isYardMoveAllowed => _isSettingAllowed(const [
        'yardMoves',
        'yardMoveEnabled',
      ]);

  bool _isSettingAllowed(List<String> keys) {
    for (final key in keys) {
      final v = fixedSettings[key];
      if (v == null) continue;
      if (v is bool) return v;
      final t = v.toString().trim().toLowerCase();
      if (t == 'allowed' || t == 'true') return true;
      if (t == 'forbidden' || t == 'false' || t.isNotEmpty) return false;
    }
    return false;
  }
}

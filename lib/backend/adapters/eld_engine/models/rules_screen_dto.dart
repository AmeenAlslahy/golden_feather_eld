import 'rules_screen_options.dart';

class RulesScreenDto {
  final String driverId;
  final String ruleSource;
  final String cycleRule;
  final String cargoType;
  final String restart;
  final String restBreak;
  final bool sixteenHourException;

  // New rule settings
  final bool personalConveyance;
  final bool yardMoves;
  final bool unlimitedTrailers;
  final bool unlimitedShippingDocuments;

  // Permissions
  final bool editable;
  final String editableBy;
  final Map<String, bool> editPermissions;

  // Existing fields
  final Map<String, List<String>> options;
  final RulesScreenLimitsDto limits;
  final List<String> editableFields;
  final List<String> readOnlyFields;
  final Map<String, dynamic> fixedSettings;
  final String notice;

  const RulesScreenDto({
    required this.driverId,
    required this.ruleSource,
    required this.cycleRule,
    required this.cargoType,
    required this.restart,
    required this.restBreak,
    required this.sixteenHourException,
    required this.options,
    required this.limits,
    required this.editableFields,
    required this.readOnlyFields,
    required this.fixedSettings,
    required this.notice,
    this.personalConveyance = false,
    this.yardMoves = false,
    this.unlimitedTrailers = false,
    this.unlimitedShippingDocuments = false,
    this.editable = false,
    this.editableBy = '',
    this.editPermissions = const {},
  });

  factory RulesScreenDto.fromJson(Map<String, dynamic> json) {
    // Support both wrapped API responses and direct data objects.
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    // New API nests settings inside "rules".
    final rules = data['rules'] is Map
        ? Map<String, dynamic>.from(data['rules'] as Map)
        : data;

    final permissions = data['editPermissions'] is Map
        ? Map<String, dynamic>.from(data['editPermissions'] as Map)
        : <String, dynamic>{};

    final parsedPermissions = <String, bool>{};

    for (final entry in permissions.entries) {
      if (entry.value is bool) {
        parsedPermissions[entry.key] = entry.value as bool;
      }
    }

    final editableList = _parseStringList(data['editableFields']);
    final editableSet = <String>{...editableList};

    const permissionFieldMap = <String, List<String>>{
      'canEditCycleRule': ['cycleRule'],
      'canEditCargoType': ['cargoType'],
      'canEditRestart': ['restart'],
      'canEditRestBreak': ['restBreak'],
      'canEditShortHaul16HourException': [
        'sixteenHourException',
        'shortHaul16HourException',
      ],
      'canEditSixteenHourException': [
        'sixteenHourException',
        'shortHaul16HourException',
      ],
      'canEditPersonalConveyance': ['personalConveyance'],
      'canEditYardMoves': ['yardMoves'],
      'canEditUnlimitedTrailers': ['unlimitedTrailers'],
      'canEditUnlimitedShippingDocuments': ['unlimitedShippingDocuments'],
    };

    for (final entry in parsedPermissions.entries) {
      if (entry.value == true) {
        final mapped = permissionFieldMap[entry.key];
        if (mapped != null) {
          editableSet.addAll(mapped);
        } else {
          editableSet.add(entry.key);
        }
      }
    }

    return RulesScreenDto(
      driverId:
          (data['driverId'] ?? data['driver'])?.toString() ?? '',

      ruleSource: data['ruleSource']?.toString() ?? '',

      cycleRule: (rules['cycleRule'] ??
              rules['ruleSetId'] ??
              data['ruleSetId'] ??
              data['cycleRule'])
          ?.toString() ??
          '',

      cargoType: (rules['cargoType'] ?? data['cargoType'])?.toString() ?? '',

      restart: (rules['restart'] ??
              rules['restartType'] ??
              data['restartType'] ??
              data['restart'])
          ?.toString() ??
          '',

      restBreak: (rules['restBreak'] ??
              rules['breakPolicy'] ??
              data['breakPolicy'] ??
              data['restBreak'])
          ?.toString() ??
          '',

      sixteenHourException: (rules['sixteenHourExceptionEnabled'] ??
              data['sixteenHourExceptionEnabled'] ??
              rules['shortHaul16HourException'] ??
              rules['sixteenHourException'] ??
              data['sixteenHourException']) ==
          true,

      personalConveyance: (rules['personalConveyanceAllowed'] ??
              data['personalConveyanceAllowed'] ??
              rules['personalConveyance'] ??
              data['personalConveyance']) ==
          true,

      yardMoves: (rules['yardMovesAllowed'] ??
              data['yardMovesAllowed'] ??
              rules['yardMoves'] ??
              data['yardMoves']) ==
          true,

      unlimitedTrailers:
          rules['unlimitedTrailers'] == true,

      unlimitedShippingDocuments:
          rules['unlimitedShippingDocuments'] == true,

      editable: data['editable'] == true,

      editableBy: data['editableBy']?.toString() ?? '',

      editPermissions: parsedPermissions,

      options: readRulesOptions(data['options']),

      limits: RulesScreenLimitsDto.fromJson(
        data['limits'] is Map
            ? Map<String, dynamic>.from(data['limits'] as Map)
            : <String, dynamic>{},
      ),

      editableFields: editableSet.toList(),

      readOnlyFields: _parseStringList(data['readOnlyFields']),

      fixedSettings: data['fixedSettings'] is Map
          ? Map<String, dynamic>.from(data['fixedSettings'] as Map)
          : <String, dynamic>{},

      notice: data['notice']?.toString() ?? '',
    );
  }

 

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return <String>[];

    return raw.map((item) => item.toString()).toList();
  }

  /// Check whether a specific field is editable.
  ///
  /// Note: Backend authorization must still be enforced.
  bool canEditField(String permissionName) {
    if (!editable) return false;

    return editPermissions[permissionName] == true;
  }
}

class RulesScreenLimitsDto {
  final int cycleHours;
  final int cycleDays;
  final int maxShiftHours;
  final int maxDrivingHours;
  final int mandatoryRestHours;
  final int restBreakMinutes;
  final int restBreakTriggerHours;

  const RulesScreenLimitsDto({
    required this.cycleHours,
    required this.cycleDays,
    required this.maxShiftHours,
    required this.maxDrivingHours,
    required this.mandatoryRestHours,
    this.restBreakMinutes = 0,
    this.restBreakTriggerHours = 0,
  });

  factory RulesScreenLimitsDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return RulesScreenLimitsDto(
      cycleHours: _parseInt(json['cycleDutyHours'] ?? json['cycleHours']),
      cycleDays: _parseInt(json['cycleDays']),
      maxShiftHours: _parseInt(json['dutyLimitHours'] ?? json['maxShiftHours']),
      maxDrivingHours: _parseInt(json['drivingLimitHours'] ?? json['maxDrivingHours']),
      mandatoryRestHours: _parseInt(json['restartHours'] ?? json['mandatoryRestHours']),
      restBreakMinutes: _parseInt(json['restBreakMinutes']),
      restBreakTriggerHours: _parseInt(json['restBreakTriggerHours']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
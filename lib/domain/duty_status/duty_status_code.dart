/// Duty status codes per FMCSA §395.3.
///
/// Wire values (e.g. `"DRIVING"`) come from the backend.
/// Short codes (e.g. `"D"`) are used in compact UI displays.
library;

import '../../../core/utils/logger.dart';

enum DutyStatusCode {
  offDuty('OFF_DUTY', 'OFF', 'off_duty'),
  sleeperBerth('SLEEPER', 'SB', 'sleeper_berth'),
  driving('DRIVING', 'D', 'driving'),
  onDutyNotDriving('ON_DUTY', 'ON', 'on_duty'),
  yardMove('YARD_MOVE', 'YM', 'yard_move'),
  personalConveyance('PERSONAL_CONVEYANCE', 'PC', 'personal_use');

  const DutyStatusCode(this.wire, this.shortCode, this.engineCode);

  /// The value sent by the backend (uppercase snake_case).
  final String wire;

  /// Short code for compact UI (e.g. log graphs).
  final String shortCode;

  /// Internal engine status string used by DutyStatusTracker.
  final String engineCode;

  /// Parses from any string format (wire, short, or engine code).
  ///
  /// ⚠️ **قيمة غير معروفة ⇒ `offDuty`** (مع تحذير). لا تستخدمه حين تكون
  /// القيمة مشكوكاً فيها وتريد التمييز بين «راحة» و«لا أعرف» — استخدم
  /// [tryFromAny].
  static DutyStatusCode fromAny(String? value) {
    if (value == null || value.isEmpty) return DutyStatusCode.offDuty;
    final upper = value.toUpperCase();
    final lower = value.toLowerCase();

    for (final c in values) {
      if (c.wire == upper || c.shortCode == upper || c.engineCode == lower) {
        return c;
      }
    }

    // Aliases for loosely typed systems
    if (upper == 'SLEEPER') {
      return DutyStatusCode.sleeperBerth;
    }
    if (lower == 'personal_conveyance') {
      return DutyStatusCode.personalConveyance;
    }

    AppLogger.warning(
      'DutyStatusCode.fromAny: unknown value "$value" — falling back to offDuty',
    );
    return DutyStatusCode.offDuty;
  }

  /// تحليل **صارم**: يعيد `null` عند قيمة غير معروفة أو فارغة.
  ///
  /// [fromAny] يرجع `offDuty` لكل ما لا يعرفه — وهو سلوك صحيح لعرض
  /// متسق، لكنه **خطير** حين تُستخدم القيمة لفرض حالة على آلة حالة:
  /// فقيمة تالفة كانت ستجبر السائق على راحة لم يطلبها.
  static DutyStatusCode? tryFromAny(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final upper = trimmed.toUpperCase();
    final lower = trimmed.toLowerCase();
    for (final c in values) {
      if (c.wire == upper || c.shortCode == upper || c.engineCode == lower) {
        return c;
      }
    }
    if (upper == 'SLEEPER') {
      return DutyStatusCode.sleeperBerth;
    }
    if (lower == 'personal_conveyance') {
      return DutyStatusCode.personalConveyance;
    }
    return null;
  }

  /// Parses from the backend wire value.
  static DutyStatusCode fromWire(String? value) => fromAny(value);

  /// Parses from a short code.
  static DutyStatusCode? fromShortCode(String? code) {
    final c = fromAny(code);
    return c == DutyStatusCode.offDuty && code?.toUpperCase() != 'OFF'
        ? null
        : c;
  }

  /// FMCSA Duty Status Code (1=OFF, 2=SB, 3=D, 4=ON)
  String toFmcsaCode() {
    switch (this) {
      case DutyStatusCode.offDuty:
      case DutyStatusCode.personalConveyance:
        return '1';
      case DutyStatusCode.sleeperBerth:
        return '2';
      case DutyStatusCode.driving:
        return '3';
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
        return '4';
    }
  }

  /// لون العرض للحالة لا يعيش هنا — النطاق لا يعرف الألوان. الخريطة
  /// اللونية الموحّدة مع الهوية في `core/utils/status_color_helper.dart`
  /// (رموز AppColors الرسمية؛ كانت هنا نسخ hex متباعدة عنها).

  /// Whether this status counts as "on-duty" for HOS purposes.
  bool get countsAsOnDuty => switch (this) {
    DutyStatusCode.offDuty => false,
    DutyStatusCode.sleeperBerth => false,
    DutyStatusCode.driving => true,
    DutyStatusCode.onDutyNotDriving => true,
    DutyStatusCode.yardMove => true,
    DutyStatusCode.personalConveyance => false,
  };

  /// The canonical 4-line grid duty status short code ('OFF', 'SB', 'D', 'ON')
  /// per FMCSA §395.2/§395.3. PC maps to 'OFF', YM maps to 'ON'.
  String get canonicalGridShortCode => switch (this) {
    DutyStatusCode.offDuty || DutyStatusCode.personalConveyance => 'OFF',
    DutyStatusCode.sleeperBerth => 'SB',
    DutyStatusCode.driving => 'D',
    DutyStatusCode.onDutyNotDriving || DutyStatusCode.yardMove => 'ON',
  };

  /// Whether this is a special driving category (PC or YM).
  bool get isSpecialDrivingCategory =>
      this == DutyStatusCode.personalConveyance ||
      this == DutyStatusCode.yardMove;

  /// Returns 'PC' or 'YM' if special driving category, otherwise null.
  String? get specialCategoryTag => switch (this) {
    DutyStatusCode.personalConveyance => 'PC',
    DutyStatusCode.yardMove => 'YM',
    _ => null,
  };

  /// Centralized normalizer: maps any status string to canonical grid short code ('OFF', 'SB', 'D', 'ON').
  static String normalizeToGridShortCode(String? status) {
    if (status == null || status.isEmpty) return 'OFF';
    return fromAny(status).canonicalGridShortCode;
  }
}

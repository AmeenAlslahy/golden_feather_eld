import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/// امتدادات BuildContext
extension ContextExtensions on BuildContext {
  // ========== السمات والترجمة ==========
  AppLocalizations get loc => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  ColorScheme get colors => theme.colorScheme;
  AppStyles get styles => theme.extension<AppStyles>()!;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ========== ترجمة حالات السائق ==========
  String translateStatus(String statusCode) {
    switch (statusCode.toUpperCase()) {
      case 'OFF': return loc.statusOff;
      case 'SB': return loc.statusSb;
      case 'D': return loc.statusD;
      case 'ON': return loc.statusOn;
      case 'PC': return loc.statusPc;
      case 'YM': return loc.statusYm;
      default: return statusCode;
    }
  }

  // ========== ترجمة حالات DVIR ==========
  String translateInspectionType(String typeCode) {
    switch (typeCode) {
      case 'preTrip': return loc.dvirPreTrip;
      case 'postTrip': return loc.dvirPostTrip;
      default: return typeCode;
    }
  }

  String translateVehicleCondition(String conditionCode) {
    switch (conditionCode) {
      case 'safe': return loc.dvirSafeToDrive;
      case 'needsRepair': return loc.dvirNeedsRepair;
      case 'unsafe': return loc.dvirUnsafe;
      default: return conditionCode;
    }
  }

  String translateInspectionItem(String itemCode) {
    switch (itemCode) {
      case 'brakes': return loc.dvirBrakes;
      case 'tires': return loc.dvirTires;
      case 'lights': return loc.dvirLights;
      case 'steering': return loc.dvirSteering;
      case 'trailerCoupling': return loc.dvirTrailerCoupling;
      case 'emergencyEquipment': return loc.dvirEmergencyEquipment;
      case 'engine': return loc.dvirEngine;
      case 'fuelSystem': return loc.dvirFuelSystem;
      case 'exhaustSystem': return loc.dvirExhaustSystem;
      case 'suspension': return loc.dvirSuspension;
      case 'mirrors': return loc.dvirMirrors;
      case 'windshield': return loc.dvirWindshield;
      default: return itemCode;
    }
  }

  // ========== الوضع واللغة ==========
  bool get isDark => theme.brightness == Brightness.dark;
  bool get isArabic =>
      Localizations.localeOf(this).languageCode == 'ar';
}




/// الألوان الدلالية المحسومة حسب الوضع.
///
/// **القاعدة:** الصفحات لا تتفرع على `isDark` ولا تستدعي `xxxFor(brightness)` —
/// كل اختيار وضع يحدث هنا مرة واحدة، والصفحة تطلب اللون الدلالي جاهزاً.
extension AppSemanticColors on BuildContext {
  /// النص الأساسي حسب الوضع.
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  /// النص الثانوي حسب الوضع.
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  /// حد الفواصل حسب الوضع.
  Color get border => isDark ? AppColors.darkBorder : AppColors.border;

  /// سطح الشاشة العام حسب الوضع.
  Color get screenSurface =>
      isDark ? AppColors.surfaceDark : AppColors.surface;

  /// الذهبي الآمن للنص حسب الخلفية (goldDeep فاتح / primaryGold داكن).
  Color get gold => isDark ? AppColors.primaryGold : AppColors.goldDeep;

  /// شريط قسم وضع التفتيش (داكن دائم بدرجتين).
  Color get inspectionBand =>
      isDark ? AppColors.inspectionBandDark : AppColors.inspectionBand;

  /// خلفية قسم دليل الأعطال.
  Color get manualBand =>
      isDark ? AppColors.manualBandDark : AppColors.manualBand;

  /// شريط رأس معاينة التفتيش — داكن في الوضعين بدرجة لكل وضع.
  Color get previewBand => isDark ? AppColors.darkBorder : AppColors.surfaceDark;
}

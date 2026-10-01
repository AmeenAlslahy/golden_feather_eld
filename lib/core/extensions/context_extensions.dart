import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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




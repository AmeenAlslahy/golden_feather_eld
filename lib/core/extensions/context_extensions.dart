import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/golden_colors.dart';

/// امتدادات BuildContext
extension ContextExtensions on BuildContext {
  // ========== السمات والترجمة ==========
  AppLocalizations get loc => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
  ThemeData get goldenTheme => theme;
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  ColorScheme get colors => theme.colorScheme;
  AppStyles get styles =>
      theme.extension<AppStyles>() ??
      AppStyles.fromBrightness(theme.brightness);
  GoldenColors get goldenColors =>
      theme.extension<GoldenColors>() ??
      (isDark ? GoldenColors.dark : GoldenColors.light);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ========== ترجمة حالات السائق ==========
  String translateStatus(String statusCode) {
    switch (statusCode.toUpperCase()) {
      case 'OFF':
        return loc.statusOff;
      case 'SB':
        return loc.statusSb;
      case 'D':
        return loc.statusD;
      case 'ON':
        return loc.statusOn;
      case 'PC':
        return loc.statusPc;
      case 'YM':
        return loc.statusYm;
      default:
        return statusCode;
    }
  }

  // ========== ترجمة حالات DVIR ==========
  String translateInspectionType(String typeCode) {
    switch (typeCode) {
      case 'preTrip':
        return loc.dvirPreTrip;
      case 'postTrip':
        return loc.dvirPostTrip;
      default:
        return typeCode;
    }
  }

  String translateVehicleCondition(String conditionCode) {
    switch (conditionCode) {
      case 'safe':
        return loc.dvirSafeToDrive;
      case 'needsRepair':
        return loc.dvirNeedsRepair;
      case 'unsafe':
        return loc.dvirUnsafe;
      default:
        return conditionCode;
    }
  }

  String translateInspectionItem(String itemCode) {
    switch (itemCode) {
      case 'brakes':
        return loc.dvirBrakes;
      case 'tires':
        return loc.dvirTires;
      case 'lights':
        return loc.dvirLights;
      case 'steering':
        return loc.dvirSteering;
      case 'trailerCoupling':
        return loc.dvirTrailerCoupling;
      case 'emergencyEquipment':
        return loc.dvirEmergencyEquipment;
      case 'engine':
        return loc.dvirEngine;
      case 'fuelSystem':
        return loc.dvirFuelSystem;
      case 'exhaustSystem':
        return loc.dvirExhaustSystem;
      case 'suspension':
        return loc.dvirSuspension;
      case 'mirrors':
        return loc.dvirMirrors;
      case 'windshield':
        return loc.dvirWindshield;
      default:
        return itemCode;
    }
  }

  // ========== الوضع واللغة ==========
  bool get isDark => theme.brightness == Brightness.dark;
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

/// الألوان الدلالية المحسومة حسب الوضع.
///
/// **القاعدة:** الصفحات لا تتفرع على `isDark` ولا تستدعي `xxxFor(brightness)` —
/// كل اختيار وضع يحدث هنا مرة واحدة، والصفحة تطلب اللون الدلالي جاهزاً.
/// في Phase 7B.1 تم تفويض الألوان الدلالية وحالات المكونات مركزياً إلى [GoldenColors].
extension AppSemanticColors on BuildContext {
  /// النص الأساسي حسب الوضع.
  Color get textPrimary => goldenColors.textPrimary;

  /// النص الثانوي حسب الوضع.
  Color get textSecondary => goldenColors.textSecondary;

  /// النص الخافت حسب الوضع.
  Color get textMuted => goldenColors.textMuted;

  /// حد الفواصل حسب الوضع.
  Color get border => goldenColors.border;

  /// الحدود القوية حسب الوضع.
  Color get borderStrong => goldenColors.borderStrong;

  /// سطح الشاشة العام حسب الوضع.
  Color get screenSurface => goldenColors.screenSurface;

  /// خلفية التطبيق العامة حسب الوضع.
  Color get background => goldenColors.background;

  /// سطح ثانوي مميز حسب الوضع.
  Color get surfaceSecondary => goldenColors.surfaceSecondary;

  /// سطح مرتفع للبطاقات حسب الوضع.
  Color get surfaceElevated => goldenColors.surfaceElevated;

  /// الذهبي الدلالي للنص حسب الوضع.
  Color get primaryText => goldenColors.primaryText;

  /// الذهبي الآمن للنص حسب الخلفية (goldDeep فاتح / primaryGold داكن).
  Color get gold => goldenColors.gold;

  /// ألوان رأس RODS الورقي الرسمي (49 CFR 395.8) — سطح فاتح ثابت
  /// للضابط بغض النظر عن سمة التطبيق؛ الوصول من الميزات عبر هنا فقط
  /// (حارس نظام التصميم يمنع AppColors المباشرة في features).
  Color get rodsHeaderBg => AppColors.rodsHeaderBg;
  Color get rodsHeaderText => AppColors.rodsHeaderText;

  Color get onGold => colors.onPrimary;

  Color get success => goldenColors.successText;

  Color get danger => goldenColors.errorText;

  Color get warning => goldenColors.warningText;

  Color get info => goldenColors.infoText;

  Color get successContainer => goldenColors.successBackground;

  Color get dangerContainer => goldenColors.errorBackground;

  Color get warningContainer => goldenColors.warningBackground;

  Color get infoContainer => goldenColors.infoBackground;

  Color get goldContainer => goldenColors.goldContainer;

  Color get divider => theme.dividerColor;

  Color get onBand => styles.onBandItem.color!;

  Color get onDark => AppColors.darkTextPrimary;

  Color get onDarkMuted => AppColors.darkTextSecondary;

  Color get successOnDark => AppColors.successOnDark;

  Color get warningOnDark => AppColors.warningOnDark;

  Color get dangerOnDark => AppColors.dangerOnDark;

  /// شريط قسم وضع التفتيش (داكن دائم بدرجتين).
  Color get inspectionBand =>
      isDark ? AppColors.inspectionBandDark : AppColors.inspectionBand;

  /// خلفية قسم دليل الأعطال.
  Color get manualBand =>
      isDark ? AppColors.manualBandDark : AppColors.manualBand;

  /// شريط رأس معاينة التفتيش — داكن في الوضعين بدرجة لكل وضع.
  Color get previewBand =>
      isDark ? AppColors.darkBorder : AppColors.surfaceDark;

  /// أسطح العناصر البديلة للصور والوسائط المتوافقة مع الوضعين.
  Color get placeholderSurface => isDark
      ? AppColors.placeholderSurfaceDark
      : AppColors.placeholderSurfaceLight;

  Color get placeholderBorder => isDark
      ? AppColors.placeholderBorderDark
      : AppColors.placeholderBorderLight;

  // =========================================================================
  // حالات المكونات المركزية (Component-State Foundations — Phase 7B.1)
  // =========================================================================

  /// لون المقدمة للعناصر المعطلة
  Color get disabledForeground => goldenColors.disabledForeground;

  /// لون السطح للعناصر المعطلة
  Color get disabledSurface => goldenColors.disabledSurface;

  /// خلفية العنصر المحدد
  Color get selectedContainer => goldenColors.selectedContainer;

  /// لون حلقة التركيز للوحة المفاتيح والحقول النشطة
  Color get focusRing => goldenColors.focusRing;

  /// طبقة التعتيم عند الضغط
  Color get pressedOverlay => goldenColors.pressedOverlay;

  /// طبقة التعتيم عند التحويم
  Color get hoverOverlay => goldenColors.hoverOverlay;
}

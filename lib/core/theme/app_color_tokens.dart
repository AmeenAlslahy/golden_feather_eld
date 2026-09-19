import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'eld_colors.dart';

/// امتداد للوصول إلى ألوان الحالات بأمان من `ThemeData`.
extension AppColorTokensExt on ThemeData {
  bool get _isDark => brightness == Brightness.dark;
  EldColors get _eld => extension<EldColors>()!;

  // ---- الذهبي ----
  Color get goldColor => _isDark ? AppColors.primaryBlue : AppColors.goldDeep;
  Color get goldLightBackground =>
      _isDark ? const Color(0xFF2A2410) : const Color(0xFFFDF8E7);
  Color get onGoldColor => AppColors.black;
  Color get onBlackColor => AppColors.primaryBlue;

  // ---- الحالات ----
  Color get successColor => _eld.successFg;
  Color get successLightBackground => _eld.successBg;
  Color get warningColor => _eld.warningFg;
  Color get warningLightBackground => _eld.warningBg;
  Color get dangerColor => _eld.dangerFg;
  Color get errorLightBackground => _eld.dangerBg;
  Color get infoColor => _eld.infoFg;
  Color get infoLightBackground => _eld.infoBg;

  // ---- ألوان إضافية ----
  Color get borderColor => _isDark ? const Color(0xFF3A3A3C) : AppColors.border;
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// امتداد للوصول إلى ألوان الحالات (Status Backgrounds) وغيرها من Tokens
extension AppColorTokensExt on ThemeData {
  bool get _isDark => brightness == Brightness.dark;

  // Semantic foreground colors
  Color get successColor => _isDark
      ? AppColors.successGreen.withValues(alpha: 0.9)
      : AppColors.successGreen;
  Color get warningColor => _isDark
      ? AppColors.warningYellow.withValues(alpha: 0.9)
      : AppColors.warningYellow;
  Color get infoColor => colorScheme.primary;
  Color get dangerColor => colorScheme.error;

  /// خلفية زرقاء خفيفة للحالات النشطة أو المعلومات
  Color get infoLightBackground => _isDark
      ? infoColor.withValues(alpha: 0.2)
      : infoColor.withValues(alpha: 0.1);

  /// خلفية خضراء خفيفة لحالات النجاح
  Color get successLightBackground => _isDark
      ? successColor.withValues(alpha: 0.2)
      : successColor.withValues(alpha: 0.1);

  /// خلفية حمراء خفيفة لحالات الخطأ
  Color get errorLightBackground => _isDark
      ? dangerColor.withValues(alpha: 0.2)
      : dangerColor.withValues(alpha: 0.1);

  /// خلفية صفراء خفيفة لحالات التحذير
  Color get warningLightBackground => _isDark
      ? warningColor.withValues(alpha: 0.2)
      : warningColor.withValues(alpha: 0.1);
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// امتداد للوصول إلى ألوان الحالات (Status Backgrounds) وغيرها من Tokens
extension AppColorTokensExt on ThemeData {
  /// خلفية زرقاء خفيفة للحالات النشطة أو المعلومات
  Color get infoLightBackground => AppColors.primaryBlue.withValues(alpha: 0.1);
  
  /// خلفية خضراء خفيفة لحالات النجاح
  Color get successLightBackground => AppColors.successGreen.withValues(alpha: 0.1);
  
  /// خلفية حمراء خفيفة لحالات الخطأ
  Color get errorLightBackground => AppColors.dangerRed.withValues(alpha: 0.1);
  
  /// خلفية صفراء خفيفة لحالات التحذير
  Color get warningLightBackground => AppColors.warningYellow.withValues(alpha: 0.1);
}

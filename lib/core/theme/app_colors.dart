import 'package:flutter/material.dart';

/// ألوان تطبيق ELD حسب دليل التصميم
class AppColors {
  AppColors._();

  // ========== الألوان الأساسية ==========
  
  /// الأزرق الأساسي - شريط العنوان والأزرار النشطة
  static const Color primaryBlue = Color(0xFF0072CE);
  
  /// الأخضر - الحالة الجيدة، زر الاتصال، حالة القيادة
  static const Color successGreen = Color(0xFF34C759);
  
  /// الأحمر - التحذير، رسائل الخطأ، الحالة الناقصة
  static const Color dangerRed = Color(0xFFFF3B30);
  
  /// الأصفر/البرتقالي - أيقونة التحذير في شريط العنوان
  static const Color warningYellow = Color(0xFFFFCC00);

  // ========== الألوان المحايدة ==========
  
  /// خلفية الصفحة
  static const Color background = Color(0xFFF2F2F7);
  
  /// حدود الحقول والفواصل
  static const Color border = Color(0xFFE5E5EA);
  
  /// النص الثانوي والتعليمات
  static const Color textSecondary = Color(0xFF6E6E73); 
  
  /// النص الأساسي
  static const Color textPrimary = Color(0xFF000000);
  
  /// خلفية البطاقات (Light)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface = surfaceLight; // For backward compatibility
  
  /// زر متابعة بدون اتصال
  static const Color darkButton = Color(0xFF2C2C2E);
  
  /// زر إرسال باهت
  static const Color paleGreen = Color(0xFFB5EAD7);

  // ========== ألوان شريط التنقل السفلي ==========
  
  /// خلفية شريط التنقل
  static const Color navBarBackground = Color(0xFFF2F2F7);
  
  /// أيقونة نشطة
  static const Color navBarActive = Color(0xFF000000);
  
  /// أيقونة غير نشطة
  static const Color navBarInactive = Color(0xFF8E8E93);

  // ========== ألوان داكنة (اختياري) ==========
  
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color surfaceDark = Color(0xFF2C2C2E);
  static const Color darkSurface = surfaceDark; // For backward compatibility
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFAEAEB2);

  // ========== التوافقية مع الكود القديم (لضمان عدم حدوث أخطاء) ==========
  static const Color primary = primaryBlue;
  static const Color primaryLight = Color(0xFFF0D675);
  static const Color onPrimary = surface;
  static const Color secondary = Color(0xFF1A1A2E);
  static const Color success = successGreen;
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = warningYellow;
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = dangerRed;
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color disabledLight = Color(0xFFE0E0E0);
  static const Color textHintLight = Color(0xFFBDBDBD);

  // ========== دوال مساعدة ==========

  static Color textPrimaryForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? textPrimary : darkTextPrimary;
  }

  static Color textSecondaryForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? textSecondary : darkTextSecondary;
  }

  static Color backgroundForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? background : darkBackground;
  }

  static Color surfaceForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? surface : darkSurface;
  }

  static Color borderForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? border : const Color(0xFF48484A);
  }
}



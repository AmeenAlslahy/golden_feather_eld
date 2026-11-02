import 'package:flutter/material.dart';

/// تعريف مركزي لكثافة المعلومات في الواجهات — Golden Feather Design System 2.0.
///
/// يُمكّن المكونات من اختيار أسلوب الكثافة المناسب بحسب طبيعة المحتوى:
/// - [compact]: للشاشات الغنية بالبيانات والجداول كالسجلات (Logs) وتفاصيل الحساب (Account Details).
/// - [comfortable]: للشاشات التفاعلية والتحقق كشاشات الدخول (Authentication) ونماذج الفحص (DVIR).
///
/// **قاعدة إمكانية الوصول:**
/// لا يقلل النمط المضغوط [compact] مساحات اللمس الأساسية عن 48.0 بكسل.
enum AppDensity {
  compact,
  comfortable;

  bool get isCompact => this == AppDensity.compact;
  bool get isComfortable => this == AppDensity.comfortable;

  /// مساحة اللمس الدنيا المحمية لضمان إمكانية الوصول في كلا النمطين (48.0)
  double get minTouchTarget => 48.0;

  /// المسافات الرأسية بين العناصر
  double get verticalGap => isCompact ? 8.0 : 16.0;

  /// الفراغ بين الحقول المتتالية
  double get fieldGap => isCompact ? 12.0 : 16.0;

  /// ارتفاع عناصر القوائم القياسية
  double get listItemHeight => isCompact ? 48.0 : 56.0;

  /// حشوة البطاقات الداخلية
  EdgeInsets get cardPadding => isCompact
      ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)
      : const EdgeInsets.all(16.0);
}

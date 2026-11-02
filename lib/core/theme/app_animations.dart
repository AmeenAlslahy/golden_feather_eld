import 'package:flutter/material.dart';

/// مدد ومنحنيات الحركة والانتقالات القياسية — Golden Feather Design System 2.0.
class AppAnimations {
  AppAnimations._();

  /// انتقال سريع (تفاعلات الضغط، الإشعارات الصغيرة): 150ms
  static const Duration fast = Duration(milliseconds: 150);

  /// انتقال قياسي (التبديل بين النماذج، أوراق السحب): 250ms
  static const Duration normal = Duration(milliseconds: 250);

  /// انتقال متأنٍ (التنقل بين الصفحات الرئيسية، الحوارات): 350ms
  static const Duration slow = Duration(milliseconds: 350);

  /// المنحنى الافتراضي للتحريك السلس المتوازن
  static const Curve defaultCurve = Curves.easeInOut;

  /// المنحنى التفاعلي عند الدخول
  static const Curve enterCurve = Curves.easeOutCubic;

  /// المنحنى التفاعلي عند الخروج
  static const Curve exitCurve = Curves.easeInCubic;
}

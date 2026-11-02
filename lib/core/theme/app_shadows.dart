import 'package:flutter/material.dart';

/// ظلال الهوية — تُستخدم في البطاقات، وتختفي في الوضع الداكن حيث يعتمد
/// الفصل البصري على درجة السطح لا على الظل.
///
/// **القاعدة:** لا تكتب `BoxShadow` في الشاشات — استخدم [AppShadows] أو
/// `AppDecorations.card`.
abstract final class AppShadows {
  AppShadows._();

  // =========================================================================
  // مواصفات الظلال والارتفاعات — Design System 2.0
  // =========================================================================

  /// بلا ظل (مسطح)
  static const List<BoxShadow> none = [];

  /// ظل خفيف جداً (الفاتح)
  static const List<BoxShadow> subtleLight = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// ظل خفيف للداكن — ناعم جداً لا يسبب وهجاً
  static const List<BoxShadow> subtleDark = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// ظل طافي للعناصر العائمة كالقوائم والأزرار العائمة (الفاتح)
  static const List<BoxShadow> floatingLight = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// ظل طافي للداكن
  static const List<BoxShadow> floatingDark = [
    BoxShadow(color: Color(0x28000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// ظل الحوارات والنوافذ المنبثقة (الفاتح)
  static const List<BoxShadow> dialogLight = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// ظل الحوارات للداكن
  static const List<BoxShadow> dialogDark = [
    BoxShadow(color: Color(0x3D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // ثوابت قياسية افتراضية (متوافقة مع الاستخدام المباشر)
  static const List<BoxShadow> subtle = subtleLight;
  static const List<BoxShadow> floating = floatingLight;
  static const List<BoxShadow> dialog = dialogLight;

  // دوال مساعدة بحسب السطوع
  static List<BoxShadow> subtleFor(Brightness b) =>
      b == Brightness.light ? subtleLight : subtleDark;

  static List<BoxShadow> floatingFor(Brightness b) =>
      b == Brightness.light ? floatingLight : floatingDark;

  static List<BoxShadow> dialogFor(Brightness b) =>
      b == Brightness.light ? dialogLight : dialogDark;

  static List<BoxShadow> cardFor(Brightness b) =>
      b == Brightness.light ? card : none;

  // =========================================================================
  // ثوابت التوافق السابقة (Legacy Shadows)
  // =========================================================================

  /// ظل البطاقة القياسي (أسود 4%، انتشار 6، هبوط 2).
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// ظل العناصر المرتفعة كرأس الدليل (أسود 5%، انتشار 8، هبوط 4).
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
}

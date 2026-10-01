import 'package:flutter/material.dart';

/// ظلال الهوية — تُستخدم في البطاقات، وتختفي في الوضع الداكن حيث يعتمد
/// الفصل البصري على درجة السطح لا على الظل.
///
/// **القاعدة:** لا تكتب `BoxShadow` في الشاشات — استخدم [AppShadows] أو
/// `AppDecorations.card`.
abstract final class AppShadows {
  AppShadows._();

  /// ظل البطاقة القياسي (أسود 4%، انتشار 6، هبوط 2).
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// ظل العناصر المرتفعة كرأس الدليل (أسود 5%، انتشار 8، هبوط 4).
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}

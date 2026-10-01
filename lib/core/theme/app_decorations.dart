import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

/// زخارف مشتركة — المصدر الوحيد لشكل البطاقات والحاويات الملوّنة.
///
/// **القاعدة:** لا تكتب `BoxDecoration(...)` في الشاشات؛ استخدم:
/// - [card] لبطاقة سطح (خلفية + حافة + ظل في الفاتح)
/// - [tinted] لحاوية ملوّنة شفافة (شارات الحالة، تنبيهات العيوب)
/// - [solid] لصندوق لون صريح (بلا حافة ولا ظل)
/// - [outlined] لصندوق بحدّ (حقول التوقيع، خلايا الجداول)
abstract final class AppDecorations {
  AppDecorations._();

  /// بطاقة سطح — الخلفية من `colorScheme.surface` والظل في الفاتح فقط.
  static BoxDecoration card(
    BuildContext context, {
    double radius = AppRadius.largeCard,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: isDark ? null : AppShadows.card,
    );
  }

  /// حاوية ملوّنة شفافة — مرّر لون **المقدمة** من زوج التباين
  /// (`context.styles.success.color!` …) وتُشتق الخلفية منه.
  static BoxDecoration tinted(
    Color foreground, {
    double alpha = 0.12,
    double radius = AppRadius.pill,
  }) {
    return BoxDecoration(
      color: foreground.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// صندوق بلون صريح بلا حافة ولا ظل (عناصر بديلة للصور، شرائط الأقسام).
  static BoxDecoration solid(Color color, {double radius = 0}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// شريط قسم كامل العرض بلون خلفية صريح.
  static BoxDecoration band(Color color) => BoxDecoration(color: color);

  /// صندوق بحدّ (حقل التوقيع، خلية رأس جدول).
  static BoxDecoration outlined({
    required Color borderColor,
    Color color = AppColors.transparent,
    double radius = 0,
    double width = 1.0,
    double alpha = 1.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor.withValues(alpha: alpha),
        width: width,
      ),
    );
  }
}

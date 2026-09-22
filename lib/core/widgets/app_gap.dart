import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// فجوات موحدة — بديل لكل `SizedBox(height: ...)` اليدوي.
///
/// **المشكلة:** 244 استخدام لـ `SizedBox(height: 8/16/24)` بقيم يدوية مبعثرة.
/// **الحل:** هوية واحدة + أسماء دلالية + لا قيم سحرية.
///
/// **الاستخدام:**
/// ```dart
/// AppGap.md  // بدلاً من SizedBox(height: 16)
/// AppGap.sm  // بدلاً من SizedBox(height: 8)
/// ```
class AppGap extends StatelessWidget {
  final double size;
  final bool isHorizontal;

  const AppGap._(this.size, {this.isHorizontal = false});

  // أحجام رأسية — الأكثر استخداماً
  static const xs = AppGap._(AppSpacing.xs);
  static const xsSm = AppGap._(AppSpacing.xsSm);
  static const sm = AppGap._(AppSpacing.sm);
  static const smMd = AppGap._(AppSpacing.smMd);
  static const md = AppGap._(AppSpacing.md);
  static const lg = AppGap._(AppSpacing.lg);
  static const xl = AppGap._(AppSpacing.xl);
  static const xxl = AppGap._(AppSpacing.xxl);
  static const xxxl = AppGap._(AppSpacing.xxxl);

  // أحجام أفقية
  static const hXs = AppGap._(AppSpacing.xs, isHorizontal: true);
  static const hXsSm = AppGap._(AppSpacing.xsSm, isHorizontal: true);
  static const hSm = AppGap._(AppSpacing.sm, isHorizontal: true);
  static const hSmMd = AppGap._(AppSpacing.smMd, isHorizontal: true);
  static const hMd = AppGap._(AppSpacing.md, isHorizontal: true);
  static const hLg = AppGap._(AppSpacing.lg, isHorizontal: true);
  static const hXl = AppGap._(AppSpacing.xl, isHorizontal: true);
  static const hXxl = AppGap._(AppSpacing.xxl, isHorizontal: true);
  static const hXxxl = AppGap._(AppSpacing.xxxl, isHorizontal: true);

  /// فجوة مخصصة — استخدمها فقط عند الحاجة لحجم غير قياسي.
  const AppGap.custom(double value, {bool horizontal = false, super.key})
      : size = value,
        isHorizontal = horizontal;

  @override
  Widget build(BuildContext context) {
    return isHorizontal ? SizedBox(width: size) : SizedBox(height: size);
  }
}

/// فجوة مرنة — تملأ المساحة المتاحة.
class AppSpacer extends StatelessWidget {
  final int flex;
  const AppSpacer({super.key, this.flex = 1});
  @override
  Widget build(BuildContext context) => Spacer(flex: flex);
}

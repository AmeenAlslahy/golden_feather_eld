import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// الأنماط الدلالية للهوية البصرية.
///
/// الاستخدام:
/// ```dart
/// Text(loc.coDriver, style: context.styles.appBarTitle);
/// Text(message, style: context.styles.body);
/// ```
///
/// لا تُنشئ `TextStyle(...)` في الشاشات إلا لحالة شاذة عبر `copyWith`.
@immutable
class AppStyles extends ThemeExtension<AppStyles> {
  const AppStyles({
    required this.appBarTitle,
    required this.pageTitle,
    required this.sectionTitle,
    required this.body,
    required this.bodyBold,
    required this.arabicBody,
    required this.subtitle,
    required this.caption,
    required this.button,
    required this.error,
    required this.success,
    required this.warning,
    required this.muted,
    required this.gold,
    required this.number,
    required this.timer,
  });

  final TextStyle appBarTitle;
  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle body;
  final TextStyle bodyBold;
  final TextStyle arabicBody;
  final TextStyle subtitle;
  final TextStyle caption;
  final TextStyle button;
  final TextStyle error;
  final TextStyle success;
  final TextStyle warning;
  final TextStyle muted;
  final TextStyle gold;
  final TextStyle number;
  final TextStyle timer;

  /// المصدر الوحيد لبناء الأنماط (SRS — خطة التصميم، اليوم 2):
  /// كان سابقاً `dark()` يعيد نسخ `light()` بأكملها (14 copyWith لكل بناء)
  /// — الآن كل نمط يُشتق من الرموز مباشرة حسب الإضاءة.
  factory AppStyles.fromBrightness(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary =
        isLight ? AppColors.textPrimary : AppColors.darkTextPrimary;
    final secondary =
        isLight ? AppColors.textSecondary : AppColors.darkTextSecondary;
    final danger = isLight ? AppColors.dangerText : AppColors.dangerOnDark;
    final success =
        isLight ? AppColors.successText : AppColors.successOnDark;
    final warning =
        isLight ? AppColors.warningText : AppColors.warningOnDark;
    final gold = isLight ? AppColors.goldDeep : AppColors.primaryGold;
    return AppStyles(
      appBarTitle: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.bold,
        color: AppColors.surface,
        height: 1.3,
      ),
      pageTitle: TextStyle(
        fontSize: AppTypography.titleSize,
        fontWeight: AppTypography.bold,
        color: primary,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      sectionTitle: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.semiBold,
        color: primary,
        height: 1.3,
      ),
      body: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        color: primary,
        height: 1.5,
      ),
      bodyBold: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.bold,
        color: primary,
        height: 1.3,
      ),
      arabicBody: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        color: primary,
        height: 1.7,
      ),
      subtitle: TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: AppTypography.regular,
        color: secondary,
        height: 1.4,
      ),
      caption: TextStyle(
        fontSize: AppTypography.smallSize,
        fontWeight: AppTypography.regular,
        color: secondary,
        letterSpacing: 0.2,
        height: 1.3,
      ),
      button: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.bold,
        color: AppColors.surface,
        letterSpacing: 0.6,
        height: 1.2,
      ),
      error: TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.w500,
        color: danger,
        height: 1.4,
      ),
      success: TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.w500,
        color: success,
        height: 1.4,
      ),
      warning: TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.w500,
        color: warning,
        height: 1.4,
      ),
      muted: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        color: secondary,
        height: 1.5,
      ),
      gold: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        color: gold,
        height: 1.5,
      ),
      number: TextStyle(
        fontSize: 18,
        fontWeight: AppTypography.bold,
        color: primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      timer: TextStyle(
        fontSize: AppTypography.timerSize,
        fontWeight: AppTypography.bold,
        color: gold,
        letterSpacing: 1,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  /// توافق خلفي — استخدم [AppStyles.fromBrightness].
  // ignore: deprecated_member_use_from_same_package
  static AppStyles light() => AppStyles.fromBrightness(Brightness.light);

  /// توافق خلفي — استخدم [AppStyles.fromBrightness].
  static AppStyles dark() => AppStyles.fromBrightness(Brightness.dark);

  @override
  AppStyles copyWith({
    TextStyle? appBarTitle,
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? body,
    TextStyle? bodyBold,
    TextStyle? arabicBody,
    TextStyle? subtitle,
    TextStyle? caption,
    TextStyle? button,
    TextStyle? error,
    TextStyle? success,
    TextStyle? warning,
    TextStyle? muted,
    TextStyle? gold,
    TextStyle? number,
    TextStyle? timer,
  }) {
    return AppStyles(
      appBarTitle: appBarTitle ?? this.appBarTitle,
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      body: body ?? this.body,
      bodyBold: bodyBold ?? this.bodyBold,
      arabicBody: arabicBody ?? this.arabicBody,
      subtitle: subtitle ?? this.subtitle,
      caption: caption ?? this.caption,
      button: button ?? this.button,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      muted: muted ?? this.muted,
      gold: gold ?? this.gold,
      number: number ?? this.number,
      timer: timer ?? this.timer,
    );
  }

  @override
  AppStyles lerp(ThemeExtension<AppStyles>? other, double t) {
    if (other is! AppStyles) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppStyles(
      appBarTitle: mix(appBarTitle, other.appBarTitle),
      pageTitle: mix(pageTitle, other.pageTitle),
      sectionTitle: mix(sectionTitle, other.sectionTitle),
      body: mix(body, other.body),
      bodyBold: mix(bodyBold, other.bodyBold),
      arabicBody: mix(arabicBody, other.arabicBody),
      subtitle: mix(subtitle, other.subtitle),
      caption: mix(caption, other.caption),
      button: mix(button, other.button),
      error: mix(error, other.error),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      muted: mix(muted, other.muted),
      gold: mix(gold, other.gold),
      number: mix(number, other.number),
      timer: mix(timer, other.timer),
    );
  }
}



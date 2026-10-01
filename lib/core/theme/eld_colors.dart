import 'package:flutter/material.dart';
import 'app_colors.dart';

/// الألوان الدلالية للهوية — أزواج آمنة (Fg / Bg).
///
/// **القاعدة:** استخدم `Fg` للنص والأيقونة، و`Bg` للخلفية. لا تخلط بينهما.
///
/// **الوصول:**
/// ```dart
/// Container(
///   color: context.eld.successBg,
///   child: Text('تم', style: TextStyle(color: context.eld.successFg)),
/// )
/// ```
class EldColors extends ThemeExtension<EldColors> {
  // ---- الذهبي (الهوية) ----
  final Color goldFg;
  final Color goldBg;
  final Color onGold;
  final Color onBlack;

  // ---- الحالات ----
  final Color successFg;
  final Color successBg;
  final Color warningFg;
  final Color warningBg;
  final Color dangerFg;
  final Color dangerBg;
  final Color infoFg;
  final Color infoBg;

  const EldColors({
    required this.goldFg,
    required this.goldBg,
    required this.onGold,
    required this.onBlack,
    required this.successFg,
    required this.successBg,
    required this.warningFg,
    required this.warningBg,
    required this.dangerFg,
    required this.dangerBg,
    required this.infoFg,
    required this.infoBg,
  });

  /// الوضع الفاتح — نصوص داكنة لضمان التباين على الخلفيات الفاتحة.
  factory EldColors.light() => const EldColors(
        goldFg: AppColors.goldDeep,
        goldBg: AppColors.goldBg,
        onGold: AppColors.onGold,
        onBlack: AppColors.onBlack,
        successFg: AppColors.successText,
        successBg: AppColors.successBg,
        warningFg: AppColors.warningText,
        warningBg: AppColors.warningBg,
        dangerFg: AppColors.dangerText,
        dangerBg: AppColors.dangerBg,
        infoFg: AppColors.infoText,
        infoBg: AppColors.infoBg,
      );

  /// الوضع الداكن — نصوص فاتحة لضمان التباين على الأسود.
  factory EldColors.dark() => const EldColors(
        goldFg: AppColors.primaryGold,
        goldBg: AppColors.darkGoldBg,
        onGold: AppColors.onGold,
        onBlack: AppColors.onBlack,
        successFg: AppColors.successOnDark,
        successBg: AppColors.darkSuccessBg,
        warningFg: AppColors.warningOnDark,
        warningBg: AppColors.darkWarningBg,
        dangerFg: AppColors.dangerOnDark,
        dangerBg: AppColors.darkDangerBg,
        infoFg: AppColors.infoOnDark,
        infoBg: AppColors.darkInfoBg,
      );

  @override
  EldColors copyWith({
    Color? goldFg,
    Color? goldBg,
    Color? onGold,
    Color? onBlack,
    Color? successFg,
    Color? successBg,
    Color? warningFg,
    Color? warningBg,
    Color? dangerFg,
    Color? dangerBg,
    Color? infoFg,
    Color? infoBg,
  }) {
    return EldColors(
      goldFg: goldFg ?? this.goldFg,
      goldBg: goldBg ?? this.goldBg,
      onGold: onGold ?? this.onGold,
      onBlack: onBlack ?? this.onBlack,
      successFg: successFg ?? this.successFg,
      successBg: successBg ?? this.successBg,
      warningFg: warningFg ?? this.warningFg,
      warningBg: warningBg ?? this.warningBg,
      dangerFg: dangerFg ?? this.dangerFg,
      dangerBg: dangerBg ?? this.dangerBg,
      infoFg: infoFg ?? this.infoFg,
      infoBg: infoBg ?? this.infoBg,
    );
  }

  @override
  EldColors lerp(covariant ThemeExtension<EldColors>? other, double t) {
    if (other is! EldColors) return this;
    return EldColors(
      goldFg: Color.lerp(goldFg, other.goldFg, t)!,
      goldBg: Color.lerp(goldBg, other.goldBg, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      onBlack: Color.lerp(onBlack, other.onBlack, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warningFg: Color.lerp(warningFg, other.warningFg, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      dangerFg: Color.lerp(dangerFg, other.dangerFg, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      infoFg: Color.lerp(infoFg, other.infoFg, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
    );
  }
}

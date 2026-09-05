import 'package:flutter/material.dart';
import 'app_colors.dart';

/// امتداد للثيم لتعريف الألوان المخصصة لتطبيق ELD التي لا تندرج 
/// تحت تصنيفات ColorScheme القياسية.
class EldColors extends ThemeExtension<EldColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color darkButton;
  final Color paleGreen;

  const EldColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.darkButton,
    required this.paleGreen,
  });

  /// إنشاء نسخة الألوان للوضع النهاري
  factory EldColors.light() {
    return const EldColors(
      success: AppColors.successGreen,
      warning: AppColors.warningYellow,
      info: AppColors.info,
      darkButton: AppColors.darkButton,
      paleGreen: AppColors.paleGreen,
    );
  }

  /// إنشاء نسخة الألوان للوضع الليلي (يمكن تخصيص درجات أغمق هنا إذا لزم الأمر مستقبلاً)
  factory EldColors.dark() {
    return const EldColors(
      // مبدئياً نستخدم نفس الألوان حتى يتم اعتماد لوحة ألوان ليلية مخصصة
      success: AppColors.successGreen,
      warning: AppColors.warningYellow,
      info: AppColors.info,
      darkButton: AppColors.darkButton,
      paleGreen: AppColors.paleGreen,
    );
  }

  @override
  ThemeExtension<EldColors> copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? darkButton,
    Color? paleGreen,
  }) {
    return EldColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      darkButton: darkButton ?? this.darkButton,
      paleGreen: paleGreen ?? this.paleGreen,
    );
  }

  @override
  ThemeExtension<EldColors> lerp(
      covariant ThemeExtension<EldColors>? other, double t) {
    if (other is! EldColors) {
      return this;
    }
    return EldColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      darkButton: Color.lerp(darkButton, other.darkButton, t)!,
      paleGreen: Color.lerp(paleGreen, other.paleGreen, t)!,
    );
  }
}

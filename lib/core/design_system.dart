/// Barrel file لنظام التصميم — استيراد واحد لكل الهوية البصرية.
///
/// ملاحظة: الملفات الفعلية باقية في مواضعها (core/theme/) — هذا الجسر
/// يتيح `import 'package:golden_feather_eld/core/design_system.dart';`
/// دون نقل ملفات يكسر 25 مستورداً (قرار المالك: لا فوضى).
library;

export 'theme/app_colors.dart';
export 'theme/app_radius.dart';
export 'theme/app_spacing.dart';
export 'theme/app_styles.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';
export 'theme/eld_colors.dart';
export 'theme/press_feedback.dart';
export 'extensions/context_extensions.dart';

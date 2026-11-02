import 'package:flutter/material.dart';
import '../theme/golden_colors.dart';

/// الأدوار الدلالية الموحدة لمكونات الحالة في التطبيق (Design System 2.0).
///
/// تمثل المصدر الموحد لحل أزواج الألوان (نص، خلفية) لجميع شارات وبصيلات الحالة.
enum StatusSemanticRole {
  success,
  error,
  warning,
  info,
  neutral;

  /// حل زوج الألوان (النص، الخلفية) بالاعتماد المباشر على [GoldenColors]
  (Color foreground, Color background) resolve(GoldenColors colors) {
    return switch (this) {
      StatusSemanticRole.success => (colors.successText, colors.successBackground),
      StatusSemanticRole.error => (colors.errorText, colors.errorBackground),
      StatusSemanticRole.warning => (colors.warningText, colors.warningBackground),
      StatusSemanticRole.info => (colors.infoText, colors.infoBackground),
      StatusSemanticRole.neutral => (colors.textMuted, colors.surfaceSecondary),
    };
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_colors.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';

/// عقود هوية الثيم — تُغلق الباب على عودة التناقضات التي أصلحتها
/// مرحلة التثبيت 2026-10-26:
/// 1. أدوار ColorScheme مثبتة بالقيم النهائية (لا تعتمد على آلية سقوط
///    خاصة بنسخة Flutter).
/// 2. وراثة tabBar في الداكن من الفاتح **مقصودة** (الشريط يعيش فوق
///    AppBar ذهبية في الوضعين) — لا "تصلحها" مستقبلاً إلى ذهبي.
/// 3. فقاعة SnackBar الداكنة منفصلة عن خلفية الشاشة.
/// 4. AppFeedback لا يعود لاستخدام inverseSurface.
/// 5. لا قيم خام داخل ملف الثيم، ولا استخدام لدور outline في الميزات
///    (الحدود والنصوص والشبكات لكل منها رمزه الدلالي).
void main() {
  group('عقود أدوار ColorScheme المثبتة', () {
    test('الحاويات: أبيض في الفاتح وsurfaceDark في الداكن', () {
      expect(AppTheme.light.colorScheme.surfaceContainer, AppColors.surface);
      expect(
        AppTheme.light.colorScheme.surfaceContainerHighest,
        AppColors.surface,
      );
      expect(
        AppTheme.dark.colorScheme.surfaceContainerHighest,
        AppColors.surfaceDark,
      );
    });

    test('outline: textPrimary فاتح / darkBorder داكن (لم يعد أبيض)', () {
      expect(AppTheme.light.colorScheme.outline, AppColors.textPrimary);
      expect(AppTheme.dark.colorScheme.outline, AppColors.darkBorder);
      expect(AppTheme.light.colorScheme.outlineVariant, AppColors.textPrimary);
      expect(AppTheme.dark.colorScheme.outlineVariant, AppColors.darkBorder);
    });
  });

  group('عقود الوضع الداكن', () {
    test('tabBar يرث الفاتح بقصد (أسود على الذهبية في الوضعين)', () {
      expect(
        AppTheme.dark.tabBarTheme.indicatorColor,
        AppTheme.light.tabBarTheme.indicatorColor,
      );
      expect(AppTheme.dark.tabBarTheme.labelColor, AppColors.onGold);
    });

    test('فقاعة SnackBar الداكنة منفصلة عن خلفية الشاشة', () {
      final darkBar = AppTheme.dark.snackBarTheme.backgroundColor;
      expect(darkBar, AppColors.surfaceDark);
      expect(darkBar, isNot(AppTheme.dark.scaffoldBackgroundColor));
    });
  });

  group('عقود المصدر (على نمط حارس التصميم)', () {
    test('AppFeedback لا يستخدم inverseSurface', () {
      final source = File(
        'lib/core/widgets/app_feedback.dart',
      ).readAsStringSync();
      expect(source.contains('inverseSurface'), isFalse);
    });

    test('لا قيم خام داخل ملف الثيم (عدا transparent المسموحة)', () {
      final source = File('lib/core/theme/app_theme.dart').readAsStringSync();
      expect(source.contains('0xFFC7C7CC'), isFalse, reason: 'radioInactive');
      expect(source.contains('0xFF48484A'), isFalse, reason: 'darkDivider');
      expect(source.contains('0xFF8E8E93'), isFalse, reason: 'disabledColor');
      // حدود كلمات: لا يلتقط AppColors.black (رمز مشروع).
      expect(RegExp(r'(?<![pP])Colors\.black').hasMatch(source), isFalse);
      expect(RegExp(r'(?<![pP])Colors\.white').hasMatch(source), isFalse);
    });

    test('لا استخدام لدور outline في الميزات — لكل نية رمزها الدلالي', () {
      final featuresDir = Directory('lib/features');
      final offenders = <String>[];
      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('colorScheme.outline')) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'استخدم context.divider أو context.textSecondary',
      );
    });
  });
}

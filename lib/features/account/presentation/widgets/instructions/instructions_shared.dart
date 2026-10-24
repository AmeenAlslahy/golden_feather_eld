import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_decorations.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// صف مقطع موحّد: عمود مرئي (صورة/عنصر) + عمود المحتوى بنفس النسب
/// في كل مقاطع صفحة التعليمات — لا محاذاة بأرقام مكررة.
class InstructionsSplitRow extends StatelessWidget {
  const InstructionsSplitRow({super.key, this.visual, required this.content});

  final Widget? visual;
  final Widget content;

  static const int _visualFlex = 4;
  static const int _contentFlex = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: _visualFlex, child: visual ?? const SizedBox.shrink()),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: _contentFlex, child: content),
      ],
    );
  }
}

/// بند قائمة بعلامة صح دائرية — للنص على الشريط الداكن الدائم.
class InstructionsChecklistItem extends StatelessWidget {
  const InstructionsChecklistItem({super.key, required this.text});

  final String text;

  static const double _iconSize = 14;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: _iconSize, color: context.onBand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.styles.onBandItem)),
        ],
      ),
    );
  }
}

/// بند قائمة بمربع صح + وصف — لبنود دليل الأعطال.
class InstructionsSquareChecklistItem extends StatelessWidget {
  const InstructionsSquareChecklistItem({
    super.key,
    required this.title,
    required this.desc,
  });

  final String title;
  final String desc;

  static const double _boxSize = 14;
  static const double _checkSize = 12;
  static const double _boxTopMargin = 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: _boxTopMargin),
            width: _boxSize,
            height: _boxSize,
            decoration: AppDecorations.solid(
              context.textPrimary.withValues(alpha: 0.54),
              radius: AppRadius.indicator,
            ),
            child: Icon(
              Icons.check,
              size: _checkSize,
              color: context.colors.surface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.styles.sheetItemTitle),
                Text(desc, style: context.styles.sheetItem),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// سطر التواصل مع الدعم — أسفل مقاطع التعليمات.
class InstructionsContactInfo extends StatelessWidget {
  const InstructionsContactInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        context.loc.contactTheSupportTeamAtTopceld,
        style: context.styles.sheetItemStrong,
        textAlign: TextAlign.center,
      ),
    );
  }
}

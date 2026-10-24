import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_decorations.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'instructions_shared.dart';

/// المقطع الثالث: دليل الأعطال (395.34) — خلفية تتبع الوضع.
class MalfunctionManualSection extends StatelessWidget {
  const MalfunctionManualSection({super.key});

  static const double _hardwareImageHeight = 120;
  static const double _hardwareIconSize = 48;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Container(
      decoration: AppDecorations.band(context.manualBand),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          InstructionsSplitRow(
            visual: Column(
              children: [
                Container(
                  height: _hardwareImageHeight,
                  decoration: AppDecorations.solid(
                    context.colors.surfaceContainerHighest,
                    radius: AppRadius.imagePlaceholder,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.router,
                      color: context.styles.subtitle.color,
                      size: _hardwareIconSize,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SmallHardwarePlaceholder(),
                    _SmallHardwarePlaceholder(),
                    _SmallHardwarePlaceholder(),
                  ],
                ),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.goldenFeatherEldMalfunctionMan,
                  style: context.styles.sheetTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.inAccordanceWithTheGuidelinesS,
                  style: context.styles.sheetCaption,
                ),
                const SizedBox(height: AppSpacing.md),
                InstructionsSquareChecklistItem(
                  title: loc.malfunctionIndication,
                  desc: loc.immediatelyContactTheSupportIf,
                ),
                InstructionsSquareChecklistItem(
                  title: loc.noteTheMalfunction,
                  desc: loc.noteTheMalfunctionAndProvideAW,
                ),
                InstructionsSquareChecklistItem(
                  title: loc.switchToPaperLogs,
                  desc: loc.keepAPaperLogForThatDayAndUnti,
                ),
                InstructionsSquareChecklistItem(
                  title: loc.k8DaysRule,
                  desc: loc.inTheEventOfAnEldMalfunctionTh,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const InstructionsContactInfo(),
        ],
      ),
    );
  }
}

/// أيقونة عتاد صغيرة بديلة للصورة.
class _SmallHardwarePlaceholder extends StatelessWidget {
  const _SmallHardwarePlaceholder();

  static const double _size = 24;
  static const double _iconSize = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: AppDecorations.solid(
        context.colors.surfaceContainerHighest,
        radius: AppRadius.pill,
      ),
      child: Icon(
        Icons.cable,
        size: _iconSize,
        color: context.styles.subtitle.color,
      ),
    );
  }
}

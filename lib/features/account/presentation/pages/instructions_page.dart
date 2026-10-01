import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Which packet item this screen shows (SRS 8.2: the Information Packet has
/// three separate items). `all` keeps the combined Instructions view.
enum InstructionsSection { all, inspection, sendLogs, malfunction }

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key, this.section = InstructionsSection.all});

  final InstructionsSection section;

  String _title(AppLocalizations loc) => switch (section) {
        InstructionsSection.all => loc.instructions,
        InstructionsSection.inspection =>
          loc.inspectionMode,
        InstructionsSection.sendLogs => loc.dataTransferInstructionSheet,
        InstructionsSection.malfunction =>
          loc.malfunctionManual39534,
      };

  @override
  Widget build(BuildContext context) {
    final showAll = section == InstructionsSection.all;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title(context.loc),
          style: context.styles.appBarTitle,
        ),
      ),
      body: ListView(
        key: Key('instructions_${section.name}'),
        padding: EdgeInsets.zero,
        children: [
          // Section 1: Inspection Mode
          if (showAll || section == InstructionsSection.inspection)
            _buildInspectionModeSection(context.loc, context),

          // Section 2: Send Logs (Data Transfer Instruction Sheet)
          if (showAll || section == InstructionsSection.sendLogs)
            _buildSendLogsSection(context.loc, context),

          // Section 3: Malfunction Manual
          if (showAll || section == InstructionsSection.malfunction)
            _buildMalfunctionManualSection(context.loc, context),
        ],
      ),
    );
  }

  Widget _buildInspectionModeSection(AppLocalizations loc, BuildContext context) {
    // شريط داكن دائم حسب التصميم المرجعي — في الوضعين.
    final sectionColor =
        context.isDark ? AppColors.inspectionBandDark : AppColors.inspectionBand;

    return Container(
      color: sectionColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for the Phone Image
          Expanded(
            flex: 4,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.smartphone, size: 64, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Text Content
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.goldenFeatherEldInspectionMode,
                  style: context.styles.bodyBold.copyWith(
                    fontSize: 18,
                    height: 1.2,
                    color: AppColors.white, // نص على شريط داكن دائم
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildChecklistItem(context: context, text: loc.tapDotInspectionInTheMenuPress),
                _buildChecklistItem(context: context, text: loc.anInspectorMayPressArrowsToVie),
                _buildChecklistItem(context: context, text: loc.anInspectorMayViewTheLogFormTh),
                _buildChecklistItem(context: context, text: loc.theOfficerCannotLeaveInspectio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendLogsSection(AppLocalizations loc, BuildContext context) {
    return Container(
      color: context.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              // Empty space to align with the text above
              const Expanded(flex: 4, child: SizedBox()),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.sendLogs,
                      style: context.styles.bodyBold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      loc.goldenFeatherEldIsCapableOfPro,
                      style:
                          context.styles.subtitle.copyWith(fontSize: 10, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _buildContactInfo(loc, context)),
        ],
      ),
    );
  }

  Widget _buildMalfunctionManualSection(
      AppLocalizations loc, BuildContext context) {
    // خلفية رمادية فاتحة فاتحة / داكنة داكنة حسب الوضع.
    final sectionColor =
        context.isDark ? AppColors.manualBandDark : AppColors.manualBand;

    return Container(
      color: sectionColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for Hardware Image
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                          child: Icon(Icons.router, color: Colors.white, size: 48)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSmallHardwarePlaceholder(),
                        _buildSmallHardwarePlaceholder(),
                        _buildSmallHardwarePlaceholder(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Text Content
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.goldenFeatherEldMalfunctionMan,
                      style: context.styles.bodyBold
                          .copyWith(fontSize: 18, height: 1.2),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      loc.inAccordanceWithTheGuidelinesS,
                      style: context.styles.caption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSquareChecklistItem(
                      context: context,
                      title: loc.malfunctionIndication,
                      desc: loc.immediatelyContactTheSupportIf,
                    ),
                    _buildSquareChecklistItem(
                      context: context,
                      title: loc.noteTheMalfunction,
                      desc: loc.noteTheMalfunctionAndProvideAW,
                    ),
                    _buildSquareChecklistItem(
                      context: context,
                      title: loc.switchToPaperLogs,
                      desc: loc.keepAPaperLogForThatDayAndUnti,
                    ),
                    _buildSquareChecklistItem(
                      context: context,
                      title: loc.k8DaysRule,
                      desc: loc.inTheEventOfAnEldMalfunctionTh,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _buildContactInfo(loc, context)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
      {required BuildContext context, required String text}) {
    // عناصر الشريط الداكن دائماً — نص أبيض على الخلفية الداكنة.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.styles.subtitle.copyWith(
                fontSize: 10,
                height: 1.4,
                color: AppColors.white, // نص على شريط داكن دائم
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareChecklistItem({
    required BuildContext context,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors
                  .black54, // Matches the dark grey square checkmark in design
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.styles.bodyBold.copyWith(fontSize: 12),
                ),
                Text(
                  desc,
                  style:
                      context.styles.subtitle.copyWith(fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(AppLocalizations loc, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'www.topceld.com',
          style:
              context.styles.subtitle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          loc.contactTheSupportTeamAtTopceld,
          style: context.styles.subtitle.copyWith(fontSize: 9),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSmallHardwarePlaceholder() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.cable, size: 14, color: Colors.white),
    );
  }
}

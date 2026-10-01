import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
    
    final brightness = Theme.of(context).brightness;
    final showAll = section == InstructionsSection.all;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title(context.loc),
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: ListView(
        key: Key('instructions_${section.name}'),
        padding: EdgeInsets.zero,
        children: [
          // Section 1: Inspection Mode
          if (showAll || section == InstructionsSection.inspection)
            _buildInspectionModeSection(context.loc, brightness),

          // Section 2: Send Logs (Data Transfer Instruction Sheet)
          if (showAll || section == InstructionsSection.sendLogs)
            _buildSendLogsSection(context.loc, brightness),

          // Section 3: Malfunction Manual
          if (showAll || section == InstructionsSection.malfunction)
            _buildMalfunctionManualSection(context.loc, brightness),
        ],
      ),
    );
  }

  Widget _buildInspectionModeSection(AppLocalizations loc, Brightness brightness) {
    // Dark background for this section as per design
    final sectionColor = brightness == Brightness.light
        ? const Color(0xFF333A45)
        : const Color(0xFF1E242C);
    const textColor = Colors.white;

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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildChecklistItem(
                  text: loc.tapDotInspectionInTheMenuPress,
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
                _buildChecklistItem(
                  text: loc.anInspectorMayPressArrowsToVie,
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
                _buildChecklistItem(
                  text: loc.anInspectorMayViewTheLogFormTh,
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
                _buildChecklistItem(
                  text: loc.theOfficerCannotLeaveInspectio,
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendLogsSection(AppLocalizations loc, Brightness brightness) {
    final sectionColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final textSecondaryColor = AppColors.textSecondaryFor(brightness);

    return Container(
      color: sectionColor,
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
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      loc.goldenFeatherEldIsCapableOfPro,
                      style: TextStyle(
                          fontSize: 10, color: textSecondaryColor, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _buildContactInfo(loc, textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildMalfunctionManualSection(AppLocalizations loc, Brightness brightness) {
    // Light gray background
    final sectionColor = brightness == Brightness.light
        ? const Color(0xFFF7F7F7)
        : const Color(0xFF1C1C1E);
    final textColor = AppColors.textPrimaryFor(brightness);
    final textSecondaryColor = AppColors.textSecondaryFor(brightness);

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
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      loc.inAccordanceWithTheGuidelinesS,
                      style: TextStyle(fontSize: 11, color: textSecondaryColor),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSquareChecklistItem(
                      title: loc.malfunctionIndication,
                      desc: loc.immediatelyContactTheSupportIf,
                      textColor: textColor,
                      secondaryColor: textSecondaryColor,
                    ),
                    _buildSquareChecklistItem(
                      title: loc.noteTheMalfunction,
                      desc: loc.noteTheMalfunctionAndProvideAW,
                      textColor: textColor,
                      secondaryColor: textSecondaryColor,
                    ),
                    _buildSquareChecklistItem(
                      title: loc.switchToPaperLogs,
                      desc: loc.keepAPaperLogForThatDayAndUnti,
                      textColor: textColor,
                      secondaryColor: textSecondaryColor,
                    ),
                    _buildSquareChecklistItem(
                      title: loc.k8DaysRule,
                      desc: loc.inTheEventOfAnEldMalfunctionTh,
                      textColor: textColor,
                      secondaryColor: textSecondaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _buildContactInfo(loc, textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
      {required String text,
      required Color textColor,
      required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareChecklistItem(
      {required String title,
      required String desc,
      required Color textColor,
      required Color secondaryColor}) {
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
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text(desc,
                    style: TextStyle(
                        fontSize: 10, color: secondaryColor, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(AppLocalizations loc, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'www.topceld.com',
          style: TextStyle(
              fontSize: 10, color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        Text(
          loc.contactTheSupportTeamAtTopceld,
          style: TextStyle(fontSize: 9, color: secondaryColor),
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

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
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
    InstructionsSection.inspection => loc.inspectionMode,
    InstructionsSection.sendLogs => loc.dataTransferInstructionSheet,
    InstructionsSection.malfunction => loc.malfunctionManual39534,
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
        title: Text(_title(context.loc), style: context.styles.appBarTitle),
      ),
      body: ListView(
        key: Key('instructions_${section.name}'),
        padding: EdgeInsets.zero,
        children: [
          // Section 1: Inspection Mode
          if (showAll || section == InstructionsSection.inspection)
            _wrapTappableSection(
              context: context,
              title: _title(context.loc),
              sectionWidget: _buildInspectionModeSection(context),
            ),

          // Section 2: Send Logs (Data Transfer Instruction Sheet)
          if (showAll || section == InstructionsSection.sendLogs)
            _wrapTappableSection(
              context: context,
              title: _title(context.loc),
              sectionWidget: _buildSendLogsSection(context),
            ),

          // Section 3: Malfunction Manual
          if (showAll || section == InstructionsSection.malfunction)
            _wrapTappableSection(
              context: context,
              title: _title(context.loc),
              sectionWidget: _buildMalfunctionManualSection(context),
            ),
        ],
      ),
    );
  }

  Widget _wrapTappableSection({
    required BuildContext context,
    required String title,
    required Widget sectionWidget,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ZoomableSectionPage(title: title, content: sectionWidget),
          ),
        );
      },
      child: sectionWidget,
    );
  }

  Widget _buildInspectionModeSection(BuildContext context) {
    final loc = context.loc;
    // شريط داكن دائم حسب التصميم المرجعي — في الوضعين.
    final sectionColor = context.inspectionBand;

    return Container(
      decoration: AppDecorations.band(sectionColor),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for the Phone Image
          Expanded(
            flex: 4,
            child: Container(
              height: 220,
              decoration: AppDecorations.solid(
                AppColors.white,
                radius: AppRadius.sheet,
              ),
              child: const Center(
                child: Icon(
                  Icons.smartphone,
                  size: 64,
                  color: AppColors.placeholderGrey,
                ),
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
                _buildChecklistItem(
                  context: context,
                  text: loc.tapDotInspectionInTheMenuPress,
                ),
                _buildChecklistItem(
                  context: context,
                  text: loc.anInspectorMayPressArrowsToVie,
                ),
                _buildChecklistItem(
                  context: context,
                  text: loc.anInspectorMayViewTheLogFormTh,
                ),
                _buildChecklistItem(
                  context: context,
                  text: loc.theOfficerCannotLeaveInspectio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendLogsSection(BuildContext context) {
    final loc = context.loc;
    return Container(
      decoration: AppDecorations.band(context.colorScheme.surface),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
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
                      style: context.styles.subtitle.copyWith(
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _buildContactInfo(context)),
        ],
      ),
    );
  }

  Widget _buildMalfunctionManualSection(BuildContext context) {
    final loc = context.loc;
    // خلفية قسم دليل الأعطال — درجة لكل وضع.
    final sectionColor = context.manualBand;

    return Container(
      decoration: AppDecorations.band(sectionColor),
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
                      decoration: AppDecorations.solid(
                        AppColors.placeholderDark,
                        radius: AppRadius.imagePlaceholder,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.router,
                          color: AppColors.white,
                          size: 48,
                        ),
                      ),
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
                      style: context.styles.bodyBold.copyWith(
                        fontSize: 18,
                        height: 1.2,
                      ),
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
          Center(child: _buildContactInfo(context)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required BuildContext context,
    required String text,
  }) {
    // عناصر الشريط الداكن دائماً — نص أبيض على الخلفية الداكنة.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.white),
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
              color: AppColors.checkSquare,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.check, size: 12, color: AppColors.white),
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
                  style: context.styles.subtitle.copyWith(
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'www.topceld.com',
          style: context.styles.subtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
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
        color: AppColors.placeholderGrey,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.cable, size: 14, color: AppColors.white),
    );
  }
}

class ZoomableSectionPage extends StatefulWidget {
  final String title;
  final Widget content;

  const ZoomableSectionPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<ZoomableSectionPage> createState() => _ZoomableSectionPageState();
}

class _ZoomableSectionPageState extends State<ZoomableSectionPage> {
  final TransformationController _controller = TransformationController();

  void _zoomIn() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale < 3.0) {
      final matrix = _controller.value.clone();
      matrix.scaleByDouble(1.2, 1.2, 1.2, 1.0);
      _controller.value = matrix;
    }
  }

  void _zoomOut() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      final matrix = _controller.value.clone();
      matrix.scaleByDouble(0.8, 0.8, 0.8, 1.0);
      if (matrix.getMaxScaleOnAxis() < 1.0) {
        matrix.setIdentity();
      }
      _controller.value = matrix;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: context.styles.appBarTitle),
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _controller,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: widget.content,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'btn_zoom_in',
                  onPressed: _zoomIn,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btn_zoom_out',
                  onPressed: _zoomOut,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.remove,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

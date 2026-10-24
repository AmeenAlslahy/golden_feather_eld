import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/instructions/instructions_zoom_overlay.dart';
import '../widgets/instructions/inspection_mode_section.dart';
import '../widgets/instructions/malfunction_manual_section.dart';
import '../widgets/instructions/send_logs_section.dart';

/// Which packet item this screen shows (SRS 8.2: the Information Packet has
/// three separate items). `all` keeps the combined Instructions view.
enum InstructionsSection { all, inspection, sendLogs, malfunction }

class InstructionsPage extends StatefulWidget {
  const InstructionsPage({super.key, this.section = InstructionsSection.all});

  final InstructionsSection section;

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  InstructionsSection? _zoomedSection;

  String _title(AppLocalizations loc) => switch (widget.section) {
    InstructionsSection.all => loc.instructions,
    InstructionsSection.inspection => loc.inspectionMode,
    InstructionsSection.sendLogs => loc.dataTransferInstructionSheet,
    InstructionsSection.malfunction => loc.malfunctionManual39534,
  };

  /// المقاطع الظاهرة — مصدر واحد يغذي القائمة وطبقة التكبير معاً.
  Map<InstructionsSection, Widget> _visibleSections() {
    final showAll = widget.section == InstructionsSection.all;
    return {
      if (showAll || widget.section == InstructionsSection.inspection)
        InstructionsSection.inspection: const InspectionModeSection(),
      if (showAll || widget.section == InstructionsSection.sendLogs)
        InstructionsSection.sendLogs: const SendLogsSection(),
      if (showAll || widget.section == InstructionsSection.malfunction)
        InstructionsSection.malfunction: const MalfunctionManualSection(),
    };
  }

  @override
  void didUpdateWidget(covariant InstructionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _zoomedSection = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections();
    final zoomedContent = _zoomedSection == null
        ? null
        : sections[_zoomedSection];

    return PopScope(
      canPop: _zoomedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _zoomedSection = null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_title(context.loc), style: context.styles.appBarTitle),
        ),
        body: Stack(
          children: [
            ListView(
              key: Key('instructions_${widget.section.name}'),
              padding: EdgeInsets.zero,
              children: [
                for (final entry in sections.entries)
                  InkWell(
                    key: Key('instructions_open_${entry.key.name}'),
                    onTap: () => setState(() => _zoomedSection = entry.key),
                    child: entry.value,
                  ),
              ],
            ),
            if (zoomedContent != null)
              InstructionsZoomOverlay(
                key: const Key('instructions_zoom_overlay'),
                onDismiss: () => setState(() => _zoomedSection = null),
                child: zoomedContent,
              ),
          ],
        ),
      ),
    );
  }
}

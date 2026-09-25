import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/widgets/eld_card.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../account/presentation/providers/rules_screen_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../duty_change_message.dart';
import '../providers/hos_engine_provider.dart';
import '../providers/hos_provider.dart';
import '../widgets/location_display_widget.dart';
import '../widgets/status_option_tiles.dart';

class ChangeStatusPage extends ConsumerStatefulWidget {
  const ChangeStatusPage({super.key});

  @override
  ConsumerState<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends ConsumerState<ChangeStatusPage> {
  late DutyStatus _selectedStatus;
  bool _isYardMoves = false;
  bool _saving = false;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final engineState = ref.read(hosStatusProvider);
    _selectedStatus = (engineState is HosEngineReady)
        ? engineState.update.currentStatus
        : DutyStatus.offDuty;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final annotation = _notesController.text.trim();

    // Validation: Annotation is required for PC and YM
    if ((_selectedStatus == DutyStatus.personalUse ||
            (_selectedStatus == DutyStatus.onDutyNotDriving && _isYardMoves)) &&
        annotation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يجب كتابة ملاحظة للقيادة الشخصية أو حركة الساحة.'
                : 'An annotation is required for personal conveyance or yard moves.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final error = await ref.read(hosStatusProvider.notifier).changeStatus(
          _selectedStatus,
          annotation: annotation.isNotEmpty ? annotation : null,
          isYardMoves: _isYardMoves,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dutyChangeMessage(context, error)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dutyChangeAcceptedMessage(context)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  String _getLocalizedStatusName(DutyStatus status) {
    switch (status) {
      case DutyStatus.offDuty:
        return context.loc.offDuty;
      case DutyStatus.sleeperBerth:
        return context.loc.sleeperBerth;
      case DutyStatus.onDutyNotDriving:
        return context.loc.onDuty;
      case DutyStatus.driving:
        return context.loc.drivingStatus;
      case DutyStatus.personalUse:
        return context.loc.personalUse;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentSpeedMs = ref.watch(currentVehicleSpeedProvider);
    final currentSpeedKmh = currentSpeedMs != null ? currentSpeedMs * 3.6 : 0.0;
    final speedThreshold =
        ref.read(hosConfigurationProvider).movingSpeedThresholdKmh;
    final isMoving = currentSpeedKmh >= speedThreshold;
    final rules = ref.watch(rulesScreenProvider).asData?.value;
    final personalConveyanceEnabled =
        rules?.fixedSettings['personalConveyanceEnabled'] == true;
    final yardMoveEnabled = rules?.fixedSettings['yardMoveEnabled'] == true;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.loc.changeStatus,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EldCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ...DutyStatus.values
                      .where((s) =>
                          s != DutyStatus.personalUse ||
                          personalConveyanceEnabled)
                      .map((status) {
                    final drivingLocked = status == DutyStatus.driving;
                    final isCurrent = _selectedStatus == status;
                    final disabled =
                        drivingLocked || (isMoving && !isCurrent);
                    return Opacity(
                      opacity: disabled ? 0.45 : 1.0,
                      child: StatusOptionTile(
                        status: status,
                        label: _getLocalizedStatusName(status),
                        isSelected: isCurrent && !drivingLocked,
                        isLast: false,
                        onTap: disabled
                            ? null
                            : () {
                                setState(() {
                                  _selectedStatus = status;
                                  if (status != DutyStatus.onDutyNotDriving) {
                                    _isYardMoves = false;
                                  }
                                });
                              },
                      ),
                    );
                  }),
                  if (yardMoveEnabled)
                    Opacity(
                      opacity: isMoving ? 0.45 : 1.0,
                      child: YardMovesOptionTile(
                        isYardMoves: _isYardMoves,
                        onTap: isMoving
                            ? null
                            : () {
                                setState(() {
                                  _isYardMoves = !_isYardMoves;
                                  if (_isYardMoves) {
                                    _selectedStatus =
                                        DutyStatus.onDutyNotDriving;
                                  }
                                });
                              },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Location & Notes Card
            EldCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.location,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const LocationDisplayWidget(),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _locationController,
                    label: context.loc.customLocation,
                    hint: context.loc.customLocation,
                    prefixIcon: const Icon(Icons.edit_location_alt),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notesController,
                    label: context.loc.notes,
                    hint: context.loc.notes,
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save Button
            AppButton(
              label: context.loc.updateButton.toUpperCase(),
              onPressed: _saving
                  ? null
                  : () {
                      if (isMoving) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.loc.errorCannotChangeStatusWhileMoving,
                            ),
                          ),
                        );
                        return;
                      }
                      _onSave();
                    },
              type: EldButtonType.send,
            ),
            if (isMoving)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  context.loc.errorCannotChangeStatusWhileMoving,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

}

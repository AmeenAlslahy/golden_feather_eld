import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/widgets/eld_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/hos_provider.dart';
import '../widgets/status_option_tiles.dart';
import '../widgets/location_display_widget.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../providers/hos_engine_provider.dart';
import '../../domain/engine/hos_rules_engine.dart';

class ChangeStatusPage extends ConsumerStatefulWidget {
  const ChangeStatusPage({super.key});

  @override
  ConsumerState<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends ConsumerState<ChangeStatusPage> {
  late DutyStatus _selectedStatus;
  bool _isYardMoves = false;
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

  void _onSave() {
    final annotation = _notesController.text.trim();

    // Validation: Annotation is required for PC and YM
    if ((_selectedStatus == DutyStatus.personalUse ||
            (_selectedStatus == DutyStatus.onDutyNotDriving && _isYardMoves)) &&
        annotation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'يجب كتابة ملاحظة (Annotation) للقيادة الشخصية أو حركة الساحة'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = ref.read(hosStatusProvider.notifier).changeStatus(
          _selectedStatus,
          annotation: annotation.isNotEmpty ? annotation : null,
          isYardMoves: _isYardMoves,
        );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.errorCannotChangeStatusWhileMoving),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.pop(context);
    }
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
            // Status Options Card
            EldCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ...DutyStatus.values
                      .where((s) => s != DutyStatus.driving)
                      .map((status) {
                    final isLast = status == DutyStatus.values.last;
                    // If moving, we can't select other statuses.
                    // To keep UI responsive, we disable tiles if isMoving is true and it's not the current status.
                    final isCurrent = _selectedStatus == status;

                    return Opacity(
                      opacity: (isMoving && !isCurrent) ? 0.5 : 1.0,
                      child: StatusOptionTile(
                        status: status,
                        label: _getLocalizedStatusName(status),
                        isSelected: isCurrent,
                        isLast: isLast && !_isYardMovesVisible,
                        onTap: (isMoving && !isCurrent)
                            ? () {}
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
                  // Yard Moves Special Option (Visible only if On Duty is selected)
                  if (_isYardMovesVisible)
                    Opacity(
                      opacity: isMoving ? 0.5 : 1.0,
                      child: YardMovesOptionTile(
                        isYardMoves: _isYardMoves,
                        onTap: isMoving
                            ? () {}
                            : () {
                                setState(() {
                                  _isYardMoves = !_isYardMoves;
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
              label: context.loc.updateButton,
              onPressed: isMoving ? null : _onSave,
              type: EldButtonType.agree,
              icon: Icons.check_circle_outline,
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

  bool get _isYardMovesVisible =>
      _selectedStatus == DutyStatus.onDutyNotDriving;
}

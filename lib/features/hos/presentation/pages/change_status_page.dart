import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/hos_provider.dart';
import '../widgets/status_option_tiles.dart';
import '../widgets/location_display_widget.dart';

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
    _selectedStatus = ref.read(hosStatusProvider).currentStatus;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSave() {
    final annotation = _notesController.text.isNotEmpty ? _notesController.text : null;

    final success = ref.read(hosStatusProvider.notifier).changeStatus(
          _selectedStatus,
          annotation: annotation,
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
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ...DutyStatus.values.map((status) {
                    final isLast = status == DutyStatus.values.last;
                    return StatusOptionTile(
                      status: status,
                      label: _getLocalizedStatusName(status),
                      isSelected: _selectedStatus == status,
                      isLast: isLast && !_isYardMovesVisible,
                      onTap: () {
                        setState(() {
                          _selectedStatus = status;
                          if (status != DutyStatus.onDutyNotDriving) {
                            _isYardMoves = false;
                          }
                        });
                      },
                    );
                  }),
                  // Yard Moves Special Option (Visible only if On Duty is selected)
                  if (_isYardMovesVisible)
                    YardMovesOptionTile(
                      isYardMoves: _isYardMoves,
                      onTap: () {
                        setState(() {
                          _isYardMoves = !_isYardMoves;
                        });
                      },
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),

            // Location & Notes Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.location,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              onPressed: _onSave,
              type: EldButtonType.agree,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  bool get _isYardMovesVisible => _selectedStatus == DutyStatus.onDutyNotDriving;
}

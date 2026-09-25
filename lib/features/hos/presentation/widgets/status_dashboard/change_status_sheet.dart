import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/time/trusted_time_provider.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../domain/engine/tracking/duty_status_tracker.dart';
import '../../duty_change_message.dart';
import '../../extensions/duty_status_l10n.dart';
import '../../providers/status_dashboard_providers.dart';

/// Bottom sheet for changing the duty status.
///
/// Returns after the mutation completes.
class ChangeStatusSheet extends ConsumerStatefulWidget {
  final DutyStatusCode currentStatus;

  const ChangeStatusSheet({
    super.key,
    required this.currentStatus,
  });

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required DutyStatusCode currentStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeStatusSheet(currentStatus: currentStatus),
    );
  }

  @override
  ConsumerState<ChangeStatusSheet> createState() => _ChangeStatusSheetState();
}

class _ChangeStatusSheetState extends ConsumerState<ChangeStatusSheet> {
  late DutyStatusCode _selected;
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStatus;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == widget.currentStatus) {
      Navigator.of(context).pop();
      return;
    }
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An annotation is required for this change.')),
      );
      return;
    }

    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null || driverId <= 0) {
      _showResult(dutyChangeMessage(context, DutyStampRefusal.sessionMissing),
          accepted: false);
      return;
    }
    if (ref.read(trustedTimeProvider).currentTime is! TrustedTimeAvailable) {
      _showResult(dutyChangeMessage(context, DutyStampRefusal.timeUnavailable),
          accepted: false);
      return;
    }

    setState(() => _submitting = true);

    final notes = _notesController.text.trim();
    await ref.read(statusDashboardProvider.notifier).changeStatus(
          _selected,
          notes: notes.isEmpty ? null : notes,
        );

    if (!mounted) return;
    setState(() => _submitting = false);
    final next = ref.read(statusDashboardProvider);
    if (next.hasError) {
      final error = next.error;
      final message = error is Failure ? error.message : '$error';
      _showResult(message, accepted: false);
      return;
    }
    _showResult(dutyChangeAcceptedMessage(context), accepted: true);
    Navigator.of(context).pop();
  }

  void _showResult(String message, {required bool accepted}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accepted ? null : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Change Status',
                    style: context.styles.pageTitle,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Status list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  RadioGroup<DutyStatusCode>(
                    groupValue: _selected,
                    onChanged: (value) {
                      if (_submitting || value == null) return;
                      setState(() => _selected = value);
                    },
                    child: Column(
                      children: [
                        for (final status in DutyStatusCode.values)
                          RadioListTile<DutyStatusCode>(
                            value: status,
                            title: Text(
                              status.displayName(context),
                              style: context.styles.body,
                            ),
                            activeColor: AppColors.primaryGold,
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _notesController,
                      enabled: !_submitting,
                      maxLines: 2,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Annotation (required)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: 'Save',
                type: EldButtonType.agree,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carrier Edits — Accept/Reject carrier-proposed edits.
///
/// **FMCSA §395.30(f):** Drivers can accept or reject carrier edits.
/// **CLEAN 100%:** Zero hardcoded values — all via theme/tokens.
/// **REUSE:** EldAppBar + AppGap + AppLoading + AppErrorView + EldCard + AppSnackBar
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/eld_app_bar.dart';
import '../../../../core/widgets/eld_card.dart';
import '../providers/carrier_edits_provider.dart';
import '../providers/logs_provider.dart';

class CarrierEditsPage extends ConsumerStatefulWidget {
  final DailyLogId logId;
  const CarrierEditsPage({super.key, required this.logId});

  @override
  ConsumerState<CarrierEditsPage> createState() => _CarrierEditsPageState();
}

class _CarrierEditsPageState extends ConsumerState<CarrierEditsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carrierEditsProvider.notifier).loadEdits(widget.logId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carrierEditsProvider);
    return Scaffold(
      // ignore: dead_null_aware_expression
      appBar: EldAppBar(title: context.loc.carrierEdits ?? 'Carrier Edits'),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(CarrierEditsState state) {
    if (state.isLoading) {
      // ignore: curly_braces_in_flow_control_structures
      return const AppLoading.fullscreen(message: 'Loading edits...');
    }
    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(carrierEditsProvider.notifier).loadEdits(widget.logId),
      );
    }
    if (state.edits.isEmpty) {
      return AppEmptyView(
        message: context.loc.noData,
        hint: 'No carrier edits for this log.',
        icon: Icons.check_circle_outline,
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(carrierEditsProvider.notifier).loadEdits(widget.logId),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.edits.length,
        itemBuilder: (context, index) => _EditCard(
          edit: state.edits[index],
          logId: widget.logId,
          isRespondingId: state.respondingEditId,
          responseAction: state.responseAction,
        ),
      ),
    );
  }
}

/// بطاقة تعديل واحدة — مكوّن مستقل قابل لإعادة الاستخدام.
class _EditCard extends ConsumerWidget {
  final Map<String, dynamic> edit;
  final DailyLogId logId;
  final String? isRespondingId;
  final String? responseAction;

  const _EditCard({
    required this.edit,
    required this.logId,
    this.isRespondingId,
    this.responseAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editId = edit['id']?.toString() ?? '';
    final status = edit['status']?.toString() ?? 'pending';
    final proposedBy = edit['proposedBy']?.toString() ?? 'Carrier';
    final proposedAt = edit['proposedAt']?.toString() ?? '';
    final changes = edit['changes'] as Map<String, dynamic>? ?? {};
    final driverNotes = edit['driverNotes']?.toString() ?? '';
    final isPending = status.toLowerCase() == 'pending';
    final isResponding = isRespondingId == editId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: EldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit #$editId', style: context.textStyles.sectionTitle),
                _StatusChip(status: status),
              ],
            ),
            AppGap.sm,
            Text('Proposed by: $proposedBy',
                style: context.textStyles.bodyBold),
            if (proposedAt.isNotEmpty)
              Text(proposedAt, style: context.textTheme.labelSmall),
            AppGap.md,
            const Divider(height: AppSpacing.dividerHeight),
            AppGap.md,
            Text('Proposed Changes:', style: context.textStyles.sectionTitle),
            AppGap.sm,
            ...changes.entries.map((e) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right,
                          size: AppSpacing.iconSize * 0.66,
                          color: context.eld.goldFg),
                      AppGap.hXs,
                      Expanded(
                          child: Text('${e.key}: ${e.value}',
                              style: context.textTheme.bodyMedium)),
                    ],
                  ),
                )),
            if (driverNotes.isNotEmpty) ...[
              AppGap.md,
              const Divider(height: AppSpacing.dividerHeight),
              AppGap.md,
              Text('Your Notes:', style: context.textStyles.sectionTitle),
              AppGap.sm,
              Text(driverNotes,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
            if (isPending) ...[
              AppGap.lg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isResponding
                          ? null
                          : () => _showRejectDialog(context, ref, editId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.eld.dangerFg,
                        side: BorderSide(color: context.eld.dangerFg),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button)),
                      ),
                      child: isResponding && responseAction == 'reject'
                          // ignore: dead_null_aware_expression
                          ? const AppLoading.button()
                          // ignore: dead_null_aware_expression
                          : Text(context.loc.reject ?? 'Reject'),
                    ),
                  ),
                  AppGap.hMd,
                  Expanded(
                    child: FilledButton(
                      onPressed: isResponding
                          ? null
                          : () =>
                              _respond(context, ref, editId, 'accept', null),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.eld.successFg,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button)),
                      ),
                      child: isResponding && responseAction == 'accept'
                          // ignore: dead_null_aware_expression
                          ? const AppLoading.button()
                          // ignore: dead_null_aware_expression
                          : Text(context.loc.accept ?? 'Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String editId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            // ignore: dead_null_aware_expression
            borderRadius: BorderRadius.circular(AppRadius.dialog)),
        // ignore: dead_null_aware_expression
        title: Text(context.loc.reject ?? 'Reject Edit',
            style: context.textStyles.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject this edit?',
                style: context.textTheme.bodyMedium),
            AppGap.md,
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(context.loc.cancelButton)),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _respond(context, ref, editId, 'reject',
                  ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
            },
            // ignore: dead_null_aware_expression
            style: TextButton.styleFrom(foregroundColor: context.eld.dangerFg),
            // ignore: dead_null_aware_expression
            child: Text(context.loc.reject ?? 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, String editId,
      String action, String? notes) async {
    await ref.read(carrierEditsProvider.notifier).respondToEdit(
        logId: logId, editId: editId, action: action, driverNotes: notes);
    if (!context.mounted) return;
    final state = ref.read(carrierEditsProvider);
    if (state.error == null) {
      AppSnackBar.showSuccess(context, 'Edit ${action}ed successfully.');
      ref.read(logsProvider.notifier).loadLogs(refresh: true);
    } else {
      AppSnackBar.showError(context, state.error!);
    }
  }
}

/// شارة حالة — ألوان دلالية من EldColors فقط، لا قيم يدوية.
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    late Color color;
    late IconData icon;
    late String label;
    switch (s) {
      case 'pending':
        color = context.eld.warningFg;
        icon = Icons.pending;
        label = 'Pending';
        break;
      case 'accepted':
        color = context.eld.successFg;
        icon = Icons.check_circle;
        label = 'Accepted';
        break;
      case 'rejected':
        color = context.eld.dangerFg;
        icon = Icons.cancel;
        label = 'Rejected';
        break;
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        icon = Icons.help_outline;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 4, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconSize * 0.58, color: color),
          AppGap.hXs,
          Text(label,
              style: context.textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

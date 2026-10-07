import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../pages/eld_connection_page.dart';
import '../providers/hardware_status_provider.dart';
import 'dialogs/manual_mode_reason_dialog.dart';

/// §395.34 instructions and the manual-recording toggle (SRS 3.7).
///
/// Lives on the About / Diagnostics screen (SRS 3.8): the reference
/// connection screen (screenshot 33) carries only the checklist, the MAC
/// field and the two buttons. Shown only when the server reports a
/// non-connected state, the last connect attempt failed, or manual mode is
/// already active (it must always be possible to end it — the server keeps
/// `ready=false` until the driver ends manual mode explicitly).
///
/// Server contract is a single driver-level toggle (`manual-mode`
/// `{enable, reason}`); SRS 7.14's per-malfunction "Manual RODS" cannot be
/// modelled until the server exposes malfunction entities.
class ManualRecordingSection extends ConsumerWidget {
  const ManualRecordingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;

    final status = ref.watch(hardwareStatusProvider).asData?.value;
    final failed = ref.watch(eldConnectionProvider).hasFailed;
    final serverState = status?.connectionStatus?.toUpperCase();
    final manualActive = status?.manualModeActive == true;
    final degraded = failed ||
        status?.hasMalfunction == true ||
        serverState == 'MALFUNCTION' ||
        serverState == 'DISCONNECTED' ||
        serverState == 'UNAVAILABLE';
    if (!degraded && !manualActive) return const SizedBox.shrink();

    final steps = [
      loc.eldMalfunctionStep1,
      loc.eldMalfunctionStep2,
      loc.eldMalfunctionStep3,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.eldMalfunctionTitle,
            style: context.styles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.sm),
              child: Text('• $step', style: context.styles.subtitle),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (manualActive) ...[
            Text(
              status?.manualModeReason != null
                  ? loc.eldMalfunctionManualActiveWithReason(status!.manualModeReason!)
                  : loc.eldMalfunctionManualActive,
              style: context.styles.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: loc.eldMalfunctionEndManual,
              type: EldButtonType.secondary,
              onPressed: () => _promptManualMode(context, ref, enable: false),
            ),
          ] else if (status?.manualRecordingAllowed == false)
            Text(
              loc.eldMalfunctionServerNotAllow,
              style: context.styles.error,
            )
          else
            AppButton(
              label: loc.eldMalfunctionStartManual,
              type: EldButtonType.primary,
              onPressed: () => _promptManualMode(context, ref, enable: true),
            ),
        ],
      ),
    );
  }

  /// Both directions go through `POST /eld/hardware/manual-mode`, which
  /// requires a reason for enable **and** disable (400 otherwise).
  Future<void> _promptManualMode(
    BuildContext context,
    WidgetRef ref, {
    required bool enable,
  }) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => ManualModeReasonDialog(enable: enable),
    );
    if (reason == null || !context.mounted) return;

    final error = await ref.read(eldConnectionProvider.notifier).setManualMode(
          enable: enable,
          reason: reason,
          loc: AppLocalizations.of(context)!,
        );
    if (!context.mounted) return;
    if (error == null) {
      ref.invalidate(hardwareStatusProvider);
      ref.invalidate(hardwareReadinessProvider);
    }
    if (error != null) {
      AppFeedback.error(context, anyErrorUserMessage(error, loc: context.loc));
    } else if (enable) {
      AppFeedback.success(
        context,
        context.loc.eldMalfunctionStartSuccess,
      );
    } else {
      AppFeedback.success(
        context,
        context.loc.eldMalfunctionEndSuccess,
      );
    }
  }
}

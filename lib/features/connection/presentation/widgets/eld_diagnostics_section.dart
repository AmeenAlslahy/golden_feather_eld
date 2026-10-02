import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../pages/eld_connection_page.dart';
import '../providers/hardware_status_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Server-side ELD connectivity status lines (SRS 3.8 diagnostics).
class EldConnectivityPanel extends ConsumerWidget {
  const EldConnectivityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final status = ref.watch(hardwareStatusProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: status.when(
        loading: () => Text(
          loc.eldDiagnosticReading,
          style: context.styles.body,
        ),
        error: (error, _) => Text(
          anyErrorUserMessage(error, loc: AppLocalizations.of(context)!),
          style: context.styles.error,
        ),
        data: (data) => _statusBody(context, data),
      ),
    );
  }

  Widget _statusBody(BuildContext context, ConnectivityStatus data) {
    final loc = context.loc;
    final lines = <String>[
      _statusLine(data, loc),
      if (data.hasDiagnostic)
        loc.eldDiagnosticDiagnosticFormat(data.diagnostics.join(', ')),
      if (data.malfunctions.isNotEmpty)
        loc.eldDiagnosticMalfunctionFormat(data.malfunctions.join(', ')),
      if (data.lastHeartbeat != null && data.lastHeartbeat!.isNotEmpty)
        loc.eldDiagnosticLastValidDataFormat(data.lastHeartbeat!),
      if (data.dataAgeSeconds != null)
        loc.eldDiagnosticDataAgeFormat(data.dataAgeSeconds!.toString()),
      if (data.normalOperationAllowed == false)
        loc.eldDiagnosticNotReady,
      if (data.isReliable == false)
        loc.eldDiagnosticDataNotReliable,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(line, style: context.styles.body),
          ),
      ],
    );
  }

  String _statusLine(ConnectivityStatus data, AppLocalizations loc) {
    switch (data.connectionStatus?.toUpperCase()) {
      case 'CONNECTED':
        return loc.eldDiagnosticConnected;
      case 'DISCONNECTED':
        return loc.eldDiagnosticDisconnected;
      case 'UNAVAILABLE':
        return loc.eldDiagnosticUnavailable;
      case 'MALFUNCTION':
        return loc.eldDiagnosticMalfunction;
      case null:
        return loc.eldDiagnosticNoConnectionStatus;
      default:
        return data.connectionStatus!;
    }
  }
}

/// `GET /eld/hardware/readiness` checklist (SRS 3.3 readiness states).
///
/// Server-owned checks are shown one per line with ✓/✗, followed by the
/// server's rejection reasons and recommended action verbatim (they are the
/// authoritative text — the app does not rephrase them).
class EldReadinessPanel extends ConsumerWidget {
  const EldReadinessPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final readiness = ref.watch(hardwareReadinessProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.eldReadinessTitle,
            style: context.styles.bodyBold,
          ),
          const SizedBox(height: AppSpacing.xs),
          readiness.when(
            loading: () => Text(
              loc.eldReadinessChecking,
              style: context.styles.body,
            ),
            error: (error, _) => Text(
              anyErrorUserMessage(error, loc: AppLocalizations.of(context)!),
              style: context.styles.error,
            ),
            data: (data) => _body(context, data, loc),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, HardwareReadiness data, AppLocalizations loc) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.ready
              ? loc.eldReadinessReady
              : loc.eldReadinessNotReady,
          style: data.ready ? context.styles.success : context.styles.error,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final entry in data.checklist.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: entry.value ? AppColors.successText : colors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    readinessCheckLabel(entry.key, loc: loc),
                    style: context.styles.body,
                  ),
                ),
              ],
            ),
          ),
        if (data.rejectionReasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          for (final reason in data.rejectionReasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.sm),
              child: Text('• $reason', style: context.styles.subtitle),
            ),
        ],
        if (data.recommendedAction != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.eldReadinessRecommendedActionFormat(data.recommendedAction!),
            style: context.styles.body,
          ),
        ],
      ],
    );
  }
}

/// Human label for a server checklist key; unknown keys are shown as-is
/// (underscores → spaces) rather than dropped.
String readinessCheckLabel(String key, {required AppLocalizations loc}) {
  switch (key) {
    case 'device_paired':
      return loc.eldReadinessDevicePaired;
    case 'connection_active':
      return loc.eldReadinessConnectionActive;
    case 'motion_data':
      return loc.eldReadinessMotionData;
    case 'location_data':
      return loc.eldReadinessLocationData;
    case 'engine_telemetry':
      return loc.eldReadinessEngineTelemetry;
    default:
      return key.replaceAll('_', ' ');
  }
}

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
              type: EldButtonType.dark,
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
              type: EldButtonType.dark,
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
      builder: (_) => _ManualModeReasonDialog(enable: enable),
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
      AppFeedback.error(context, error);
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

/// Owns its text controller so it is disposed with the route, after the
/// dialog's exit animation — not while the TextField is still attached.
class _ManualModeReasonDialog extends StatefulWidget {
  const _ManualModeReasonDialog({required this.enable});

  final bool enable;

  @override
  State<_ManualModeReasonDialog> createState() => _ManualModeReasonDialogState();
}

class _ManualModeReasonDialogState extends State<_ManualModeReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final enable = widget.enable;
    return AlertDialog(
      title: Text(
        enable
            ? loc.eldMalfunctionReasonStart
            : loc.eldMalfunctionReasonEnd,
      ),
      content: AppTextField(
        controller: _controller,
        maxLines: 2,
        hint: enable
            ? loc.eldMalfunctionHintStart
            : loc.eldMalfunctionHintEnd,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(loc.okButton),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/hardware_status_provider.dart';

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

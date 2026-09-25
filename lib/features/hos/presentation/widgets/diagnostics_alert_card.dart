import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../connection/presentation/providers/hardware_alerts_provider.dart';

/// Driver diagnostic display. It shows `/eld/hardware/alerts` only.
/// A local malfunction engine is not a legal record.
class DiagnosticsAlertCard extends ConsumerWidget {
  const DiagnosticsAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(hardwareAlertsProvider);
    return alerts.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => _line(
        context,
        'Hardware alerts were not loaded: $error',
        isError: true,
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final alert in items)
              _line(context, alert.message, isError: true),
          ],
        );
      },
    );
  }

  Widget _line(BuildContext context, String message, {required bool isError}) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: color, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

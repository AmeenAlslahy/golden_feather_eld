import 'package:flutter/material.dart';

import '../../../../../core/design_system.dart';
import '../../../domain/entities/hardware_alert.dart';

class StatRow extends StatelessWidget {
  final List<HardwareAlert> alerts;
  final List<HardwareAlert> malfunctions;

  const StatRow({super.key, required this.alerts, required this.malfunctions});

  @override
  Widget build(BuildContext context) {
    final diagnostics = alerts.length - malfunctions.length;
    String two(int v) => v.toString().padLeft(2, '0');
    final stats = [
      _StatCard(context.loc.active, two(alerts.length)),
      _StatCard(context.loc.diagnosticEvents, two(diagnostics)),
      _StatCard(context.loc.malfunctionAlerts, two(malfunctions.length)),
      _StatCard(context.loc.allEvents, two(diagnostics)),
      _StatCard(context.loc.malfunctionAlerts, two(malfunctions.length)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: stats
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return EldCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text(value, style: context.styles.number),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.styles.caption,
          ),
        ],
      ),
    );
  }
}

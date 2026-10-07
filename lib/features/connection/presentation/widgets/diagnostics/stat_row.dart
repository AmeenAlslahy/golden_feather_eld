import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/hardware_alert.dart';

class StatRow extends StatelessWidget {
  final List<HardwareAlert> alerts;
  final List<HardwareAlert> malfunctions;

  const StatRow({
    super.key,
    required this.alerts,
    required this.malfunctions,
  });

  @override
  Widget build(BuildContext context) {
    final diagnostics = alerts.length - malfunctions.length;
    String two(int v) => v.toString().padLeft(2, '0');
    return Row(
      children: [
        _StatCard(context.loc.active, two(alerts.length)),
        _StatCard('ACTIVE DIAG', two(diagnostics)),
        _StatCard('ACTIVE MALF', two(malfunctions.length)),
        _StatCard('TOTAL DIAG', two(diagnostics)),
        _StatCard('TOTAL MALF', two(malfunctions.length)),
      ].map((w) => Expanded(child: w)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: 4),
        child: Column(
          children: [
            Text(value, style: context.styles.number),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: context.styles.caption.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../../core/domain/duty_status/status_dashboard.dart';
import '../circular_timer_widget.dart';

/// Status Dashboard wrapper around [CircularTimerWidget].
///
/// **CLEAN-HIGH-03 fix:** Delegates to the unified widget, converting
/// [RemainingCircle] domain entity into simple display parameters.
class MainCircularTimer extends StatelessWidget {
  final RemainingCircle circle;
  final String statusLabel;
  final VoidCallback? onTap;

  const MainCircularTimer({
    super.key,
    required this.circle,
    required this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CircularTimerWidget(
      progress: circle.progress,
      timeString: _formatDuration(circle.remaining),
      label: circle.label,
      statusText: statusLabel,
      isCritical: circle.isCritical,
      isExpired: circle.isExpired,
      onTap: onTap,
    );
  }

  static String _formatDuration(Duration duration) {
    final negative = duration.isNegative;
    final abs = duration.abs();
    final hours = abs.inHours;
    final minutes = abs.inMinutes.remainder(60);
    final sign = negative ? '-' : '';
    return '$sign${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }
}

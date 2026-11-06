import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../extensions/duty_status_l10n.dart';
import '../providers/status_dashboard_providers.dart';
import '../widgets/status_dashboard/circular_timer_logic.dart';
import '../widgets/status_dashboard/hos_indicators_card.dart';
import '../widgets/status_dashboard/main_circular_timer.dart';
import 'change_status_page.dart';
import '../../../../l10n/app_localizations.dart';

/// Main driver dashboard — status, remaining time, HOS indicators.
///
/// Backed by [statusDashboardProvider].
class StatusDashboardPage extends ConsumerWidget {
  const StatusDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statusDashboardProvider);

    return state.when(
      skipError: true,
      loading: () => const _LoadingView(),
      error: (error, _) {
        if (error is SessionMissingFailure) {
          return const _LoadingView();
        }
        return _ErrorView(
          error: error,
          onRetry: () =>
              ref.read(statusDashboardProvider.notifier).clearErrorAndReload(),
        );
      },
      data: (dashboard) => _DashboardView(dashboard: dashboard),
    );
  }
}

// =============================================================================
// Data view
// =============================================================================

class _DashboardView extends ConsumerStatefulWidget {
  final StatusDashboard dashboard;

  const _DashboardView({required this.dashboard});

  @override
  ConsumerState<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<_DashboardView> {
  Timer? _ticker;
  late final Stopwatch _stopwatch;
  late final ValueNotifier<Duration> _elapsedNotifier;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _elapsedNotifier = ValueNotifier(_computeElapsed());
    _startTickerIfNeeded();
  }

  Duration _computeElapsed() {
    final snapshotTimestamp = ref.read(
      statusDashboardSnapshotTimestampProvider,
    );
    return computeElapsedSinceSnapshot(
      trustedTime: ref.read(trustedTimeProvider).currentTime,
      snapshotTimestamp: snapshotTimestamp,
      stopwatchElapsed: _stopwatch.elapsed,
    );
  }

  bool get _isRestDuty => CircularTimerLogic.isRestDuty(
    widget.dashboard.currentDutyStatus,
    widget.dashboard.currentDutyStatus.wire,
  );

  bool get _isActiveDuty => CircularTimerLogic.isActiveDuty(
    widget.dashboard.currentDutyStatus,
    _isRestDuty,
  );

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    _ticker = null;
    if (_isActiveDuty) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _elapsedNotifier.value = _computeElapsed();
      });
    }
  }

  void _resetTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _elapsedNotifier.value = _computeElapsed();
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(_DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboard.currentDutyStatus !=
        widget.dashboard.currentDutyStatus) {
      _resetTimer();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(statusDashboardSnapshotTimestampProvider, (prev, next) {
      if (prev != next) {
        _resetTimer();
      }
    });

    final snapshotTimestamp = ref.watch(
      statusDashboardSnapshotTimestampProvider,
    );
    final cycleHours =
        widget.dashboard.regulatoryConstraints.ruleSet.cycleHours;
    final statusLabel = widget.dashboard.currentDutyStatus.displayName(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: MainCircularTimer(
                circle: widget.dashboard.remainingCircle,
                statusLabel: statusLabel,
                dutyStatus: widget.dashboard.currentDutyStatus,
                hosIndicators: widget.dashboard.hosIndicators,
                snapshotTimestamp: snapshotTimestamp,
                elapsedNotifier: _elapsedNotifier,
                cycleLimit: Duration(
                  hours: cycleHours > 0 ? cycleHours : 70,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangeStatusPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Reference layout: full-width table, no card inset.
            //
            // نفس `snapshotTimestamp` ونفس `_elapsedNotifier`:
            // البطاقة تقصّ الثانية نفسها التي تقصّها الدائرة تماماً بمؤقت واحد.
            HosIndicatorsCard(
              indicators: widget.dashboard.hosIndicators,
              constraints: widget.dashboard.regulatoryConstraints,
              snapshotTimestamp: snapshotTimestamp,
              dutyStatus: widget.dashboard.currentDutyStatus,
              statusLabel: statusLabel,
              elapsedNotifier: _elapsedNotifier,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Loading view
// =============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// =============================================================================
// Error view
// =============================================================================

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EldRetryView(
      message: anyErrorUserMessage(error, loc: AppLocalizations.of(context)!),
      onRetry: onRetry,
    );
  }
}

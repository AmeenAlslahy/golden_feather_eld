import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../extensions/duty_status_l10n.dart';
import '../providers/status_dashboard_providers.dart';
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
      loading: () => const _LoadingView(),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.read(statusDashboardProvider.notifier).clearErrorAndReload(),
      ),
      data: (dashboard) => _DashboardView(dashboard: dashboard),
    );
  }
}

// =============================================================================
// Data view
// =============================================================================

class _DashboardView extends ConsumerWidget {
  final StatusDashboard dashboard;

  const _DashboardView({required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(statusDashboardProvider.notifier).refresh(),
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  MainCircularTimer(
                    circle: dashboard.remainingCircle,
                    statusLabel: dashboard.currentDutyStatus.displayName(context),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangeStatusPage(),
                        ),
                      ).then((_) {
                        ref.read(statusDashboardProvider.notifier).refresh();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Reference layout: full-width table, no card inset.
                  HosIndicatorsCard(
                    indicators: dashboard.hosIndicators,
                    constraints: dashboard.regulatoryConstraints,
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
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
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// =============================================================================
// Error view
// =============================================================================

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EldRetryView(
      message: anyErrorUserMessage(error, loc: AppLocalizations.of(context)!),
      onRetry: onRetry,
    );
  }
}

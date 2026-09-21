import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart' as f;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../extensions/duty_status_l10n.dart';
import '../providers/status_dashboard_providers.dart';
import '../widgets/status_dashboard/change_status_sheet.dart';
import '../widgets/status_dashboard/hos_indicators_card.dart';
import '../widgets/status_dashboard/main_circular_timer.dart';
import '../widgets/status_dashboard/operational_alerts_banner.dart';

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

class _DashboardView extends StatelessWidget {
  final StatusDashboard dashboard;

  const _DashboardView({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          OperationalAlertsBanner(alerts: dashboard.operationalAlerts),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  if (dashboard.regulatoryConstraints.ruleSet !=
                          CycleRule.unknown)
                    Chip(
                      label: Text(
                        dashboard.regulatoryConstraints.ruleSet.wire.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppColors.background,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  MainCircularTimer(
                    circle: dashboard.remainingCircle,
                    statusLabel: dashboard.currentDutyStatus.displayName(context),
                    onTap: () => ChangeStatusSheet.show(
                      context,
                      currentStatus: dashboard.currentDutyStatus,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: HosIndicatorsCard(
                      indicators: dashboard.hosIndicators,
                    ),
                  ),
                ],
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
    String message = 'حدث خطأ غير متوقع'; // Fallback user message

    if (error is f.Failure) {
      final fail = error as f.Failure;
      if (fail is f.NetworkFailure) {
        message = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
      } else if (fail is f.ServerFailure) {
        message = 'حدثت مشكلة في الاتصال بالخادم. يرجى المحاولة لاحقاً.';
      } else {
        // We avoid printing raw developer messages here
        message = 'فشل في العملية. الرجاء المحاولة مرة أخرى.';
      }
    } else if (error is AppError) {
      message = (error as AppError).l10nKey;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.dangerRed,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.bodySize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

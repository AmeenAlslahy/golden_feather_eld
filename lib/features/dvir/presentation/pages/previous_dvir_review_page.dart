/// Previous DVIR Review Screen — review and acknowledge previous DVIR.
///
/// **FMCSA §396.13:** Before operating a vehicle, driver must review
/// the previous DVIR and sign if defects were noted and repaired.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/eld_app_bar.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../dvir/domain/entities/dvir_report.dart';
import '../../../dvir/presentation/providers/dvir_provider.dart';

class PreviousDvirReviewPage extends ConsumerStatefulWidget {
  const PreviousDvirReviewPage({super.key});

  @override
  ConsumerState<PreviousDvirReviewPage> createState() =>
      _PreviousDvirReviewPageState();
}

class _PreviousDvirReviewPageState
    extends ConsumerState<PreviousDvirReviewPage> {
  @override
  void initState() {
    super.initState();
    // dvirProvider automatically loads DVIRs in its constructor
  }

  @override
  Widget build(BuildContext context) {
    final dvirState = ref.watch(dvirProvider);

    return Scaffold(
      appBar: EldAppBar(title: context.loc.previousDvirReview ?? 'Previous DVIR Review'),
      body: _buildBody(context, dvirState),
    );
  }

  Widget _buildBody(BuildContext context, DvirState dvirState) {
    if (dvirState.isLoading) {
      return const AppLoading.fullscreen();
    }

    if (dvirState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: AppSpacing.iconSize * 2.66, color: AppColors.dangerRed),
            AppGap.md,
            Text(dvirState.error!, textAlign: TextAlign.center),
            AppGap.lg,
            ElevatedButton(
              onPressed: () =>
                  ref.read(dvirProvider.notifier).loadDvirs(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Find the most recent DVIR that needs review
    final previousDvir = _findPreviousDvir(dvirState.reports);

    if (previousDvir == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: AppSpacing.iconSize * 2.66,
              color: AppColors.successGreen.withValues(alpha: 0.5),
            ),
            AppGap.md,
            Text(
              'No Previous DVIR to Review',
              style: AppTextStyles(context).pageTitle,
            ),
            AppGap.sm,
            Text(
              'All previous DVIR reports have been reviewed.',
              style: AppTextStyles(context).body,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.primaryBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primaryBlue),
                AppGap.hSm,
                Expanded(
                  child: Text(
                    'Per FMCSA §396.13: Before operating a vehicle, you must review the previous DVIR.',
                    style: AppTextStyles(context).body.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                  ),
                ),
              ],
            ),
          ),

          AppGap.lg,

          // Previous DVIR details
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Previous DVIR Report',
                  style: AppTextStyles(context).pageTitle,
                ),
                AppGap.md,
                _buildInfoRow(
                    context, 'Report ID', previousDvir.id),
                _buildInfoRow(
                    context, 'Vehicle', previousDvir.vehicleId),
                _buildInfoRow(
                    context,
                    'Date',
                    previousDvir.date
                        .toLocal()
                        .toString()
                        .split(' ')[0]),
                _buildInfoRow(
                    context, 'Driver', previousDvir.driverName),
                _buildInfoRow(
                    context,
                    'Type',
                    previousDvir.type.englishName),
                _buildInfoRow(
                    context,
                    'Condition',
                    previousDvir.condition.englishName),
              ],
            ),
          ),

          AppGap.lg,

          // Defects
          if (previousDvir.hasDefects) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.warningYellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warningYellow),
                      AppGap.hSm,
                      Text(
                        'Defects Found (${previousDvir.defectsCount})',
                        style: AppTextStyles(context).pageTitle.copyWith(
                              color: AppColors.warningYellow,
                            ),
                      ),
                    ],
                  ),
                  AppGap.sm,
                  if (previousDvir.defectsSummary != null &&
                      previousDvir.defectsSummary!.isNotEmpty)
                    Text(
                      previousDvir.defectsSummary!,
                      style: AppTextStyles(context).body,
                    ),
                  AppGap.md,
                  if (previousDvir.certified) ...[
                    const Divider(),
                    AppGap.sm,
                    Row(
                      children: [
                        const Icon(Icons.build_circle,
                            color: AppColors.successGreen, size: 20),
                        AppGap.hSm,
                        Expanded(
                          child: Text(
                            'Defects have been repaired and certified by: ${previousDvir.mechanicName ?? 'Mechanic'}',
                            style: AppTextStyles(context).body.copyWith(
                                  color: AppColors.successGreen,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppGap.lg,
          ],

          // Review button
          ElevatedButton(
            onPressed: () => _acknowledgeReview(context, previousDvir),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              'I Have Reviewed This DVIR',
              style: AppTextStyles(context)
                  .buttonText
                  .copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles(context).bodyBold,
          ),
          Text(
            value,
            style: AppTextStyles(context).body,
          ),
        ],
      ),
    );
  }

  DvirReport? _findPreviousDvir(List<DvirReport> dvirs) {
    if (dvirs.isEmpty) return null;

    // Find the most recent DVIR that hasn't been reviewed by next driver
    for (final dvir in dvirs) {
      if (!dvir.nextDriverReviewed) {
        return dvir;
      }
    }

    return null;
  }

  Future<void> _acknowledgeReview(
      BuildContext context, DvirReport dvir) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Review'),
        content: const Text(
            'By confirming, you acknowledge that you have reviewed the previous DVIR report and are aware of any defects and repairs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authUser = ref.read(authStateProvider).user;
      final driverId = int.tryParse(authUser?.id ?? '') ?? 0;
      final driverName = authUser?.fullName ?? 'Driver';
      await ref.read(dvirProvider.notifier).reviewDvir(
            dvirId: dvir.id,
            reviewingDriverId: driverId,
            reviewingDriverName: driverName,
            signatureData: '',
            driverAgreed: true,
          );
      if (!mounted) return;
      final dvirState = ref.read(dvirProvider);
      if (dvirState.error != null) {
        if (!mounted) return;
        AppSnackBar.showError(context, dvirState.error!);
        return;
      }
      if (!mounted) return;
      AppSnackBar.showSuccess(context, context.loc.successMessage);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString());
    }
  }
}

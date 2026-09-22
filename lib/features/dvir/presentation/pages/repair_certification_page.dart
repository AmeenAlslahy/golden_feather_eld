/// Repair Certification Screen — certify that vehicle defects are fixed.
///
/// **FMCSA §396.11(a)(2):** Mechanic/technician certifies repair completion.
/// Driver reviews and acknowledges the certification before next trip.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

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

class RepairCertificationPage extends ConsumerStatefulWidget {
  final DvirReport dvirReport;

  const RepairCertificationPage({super.key, required this.dvirReport});

  @override
  ConsumerState<RepairCertificationPage> createState() =>
      _RepairCertificationPageState();
}

class _RepairCertificationPageState
    extends ConsumerState<RepairCertificationPage> {
  late SignatureController _signatureController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.primaryGold,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // exportBackgroundColor is final, set in constructor only
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: dead_null_aware_expression
      appBar: EldAppBar(title: context.loc.repairCertification ?? 'repairCertification'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DVIR Info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.primaryBlue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DVIR Report',
                      style: AppTextStyles(context).pageTitle,
                    ),
                    AppGap.sm,
                    _buildInfoRow(context, 'Report ID', widget.dvirReport.id),
                    _buildInfoRow(context, 'Vehicle',
                        widget.dvirReport.vehicleId),
                    _buildInfoRow(
                        context,
                        'Date',
                        widget.dvirReport.date
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                  ],
                ),
              ),

              AppGap.lg,

              // Defects
              if (widget.dvirReport.hasDefects)
                _buildDefectsList(context)
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.successGreen),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.successGreen),
                      AppGap.hSm,
                      Expanded(
                        child: Text(
                          'No defects reported. No repair certification needed.',
                          style: AppTextStyles(context).body.copyWith(
                                color: AppColors.successGreen,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              AppGap.lg,

              // Mechanic signature (if already certified)
              if (widget.dvirReport.certified)
                _buildMechanicCertification(context),

              AppGap.lg,

              // Driver acknowledgment
              if (widget.dvirReport.certified &&
                  !widget.dvirReport.nextDriverReviewed)
                _buildDriverAcknowledgment(context),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.dangerRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.dangerRed),
                        AppGap.hSm,
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles(context)
                                .body
                                .copyWith(color: AppColors.dangerRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Widget _buildDefectsList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningYellow.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warningYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Defects Found',
            style: AppTextStyles(context).pageTitle.copyWith(
                  color: AppColors.warningYellow,
                ),
          ),
          AppGap.sm,
          // List defects from DVIR report
          if (widget.dvirReport.defectsSummary != null &&
              widget.dvirReport.defectsSummary!.isNotEmpty)
            ...widget.dvirReport.defectsSummary!
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .map((defect) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.warningYellow),
                          AppGap.hSm,
                          Expanded(
                            child: Text(
                              defect,
                              style: AppTextStyles(context).body,
                            ),
                          ),
                        ],
                      ),
                    )),
        ],
      ),
    );
  }

  Widget _buildMechanicCertification(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.successGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_circle, color: AppColors.successGreen),
              AppGap.hSm,
              Text(
                'Mechanic Certification',
                style: AppTextStyles(context).pageTitle.copyWith(
                      color: AppColors.successGreen,
                    ),
              ),
            ],
          ),
          AppGap.sm,
          Text(
            'I certify that the defects listed above have been repaired and the vehicle is safe to operate.',
            style: AppTextStyles(context).body,
          ),
          AppGap.sm,
          Text(
            'Certified by: Mechanic',
            style: AppTextStyles(context).bodyBold,
          ),
          Text(
            'Date: ${widget.dvirReport.mechanicSignatureDate}',
            style: AppTextStyles(context).body,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverAcknowledgment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Driver Acknowledgment',
          style: AppTextStyles(context).pageTitle,
        ),
        AppGap.sm,
        Text(
          'By signing below, I acknowledge that I have reviewed the repair certification and the vehicle is ready for operation.',
          style: AppTextStyles(context).body,
        ),
        AppGap.md,

        // Signature pad
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Signature(
            controller: _signatureController,
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        AppGap.sm,

        // Clear signature button
        TextButton(
          onPressed: () => _signatureController.clear(),
          child: Text(
            // ignore: dead_null_aware_expression
            context.loc.clearSignature ?? 'Clear Signature',
            style: AppTextStyles(context).body.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
        AppGap.md,

        // Submit button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAcknowledgment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                )
              : Text(
                  // ignore: dead_null_aware_expression
                  context.loc.agree ?? 'Acknowledge & Submit',
                  style: AppTextStyles(context)
                      .buttonText
                      .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                ),
        ),
      ],
    );
  }

  Future<void> _submitAcknowledgment() async {
    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null || signatureBytes.isEmpty) {
      setState(() {
        _error = context.loc.signatureRequired;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Real API: driver reviews repair certification
      final authUser = ref.read(authStateProvider).user;
      final driverId = int.tryParse(authUser?.id ?? '') ?? 0;
      final driverName = authUser?.fullName ?? 'Driver';
      final signatureData = signatureBytes.isNotEmpty ? 'data:image/png;base64,${base64Encode(signatureBytes)}' : '';

      await ref.read(dvirProvider.notifier).reviewDvir(
            dvirId: widget.dvirReport.id,
            reviewingDriverId: driverId,
            reviewingDriverName: driverName,
            signatureData: signatureData,
            driverAgreed: true,
          );

      if (!mounted) return;
      final dvirState = ref.read(dvirProvider);
      if (dvirState.error != null) {
        setState(() {
          _error = dvirState.error;
        });
        return;
      }

      if (!mounted) return;
      AppSnackBar.showSuccess(context, context.loc.successMessage);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

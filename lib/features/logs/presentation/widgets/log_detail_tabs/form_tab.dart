/// Form Tab — Atomic Save per SRS §5.13.
///
/// **API Integration:** Uses [dailyFormProvider] to load/save form data
/// via `GET/PUT /eld/daily-logs/{id}/form`.
///
/// **Atomic Save:** All form elements (vehicles, trailers, shipping
/// documents, co-driver) are sent in ONE request. Either all save or none.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_gap.dart';
import '../../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../vehicle/domain/entities/vehicle.dart';
import '../../pages/shipping_documents_page.dart';
import '../../pages/trailers_page.dart';
import '../../providers/form_provider.dart';
import '../../providers/logs_provider.dart';
import '../../widgets/codriver_picker_dialog.dart';
import '../../widgets/vehicle_picker_dialog.dart';

class FormTab extends ConsumerStatefulWidget {
  const FormTab({super.key});

  @override
  ConsumerState<FormTab> createState() => _FormTabState();
}

class _FormTabState extends ConsumerState<FormTab> {
  @override
  void initState() {
    super.initState();
    // Load form data from API when tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedLog = ref.read(logsProvider).selectedLog;
      if (selectedLog != null) {
        ref.read(dailyFormProvider.notifier).loadForm(selectedLog.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final formState = ref.watch(dailyFormProvider);
    final selectedLog = ref.watch(logsProvider).selectedLog;

    if (selectedLog == null) {
      return Center(child: Text(context.loc.noData));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========== Driver (read-only) ==========
          _buildFormRow(context, context.loc.driver, dashboard.driverName),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          // ========== Vehicle (editable) ==========
          _buildFormRow(
            context,
            context.loc.vehicles,
            dashboard.vehicleDisplayName,
            onEdit: () async {
              final vehicle = await showDialog<Vehicle>(
                context: context,
                builder: (_) =>
                    VehiclePickerDialog(currentVehicleId: dashboard.vehicleId),
              );
              if (vehicle != null && context.mounted) {
                ref.read(dashboardDataProvider.notifier).updateVehicle(vehicle);
                // Update form state with vehicle uniqueId
                ref
                    .read(dailyFormProvider.notifier)
                    .setUniqueId(vehicle.id);
              }
            },
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          // ========== Trailers (editable) ==========
          _buildFormRow(
            context,
            context.loc.trailers,
            formState.trailers.isEmpty
                ? '-'
                : formState.trailers
                    .map((t) => t['trailerNumber'] ?? '')
                    .join(', '),
            onEdit: () async {
              final result = await Navigator.push<List<String>>(
                context,
                MaterialPageRoute(builder: (_) => const TrailersPage()),
              );
              if (result != null && context.mounted) {
                // Sync trailers from result to form state
                ref.read(dailyFormProvider.notifier).state = ref.read(dailyFormProvider).copyWith(
                      trailers: result
                          .map((t) => {'trailerNumber': t})
                          .toList(),
                    );
              }
            },
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          // ========== Shipping Documents (editable) ==========
          _buildFormRow(
            context,
            context.loc.shippingDocuments,
            formState.shippingDocuments.isEmpty
                ? '-'
                : formState.shippingDocuments
                    .map((d) => d['documentNumber'] ?? '')
                    .join(', '),
            onEdit: () async {
              final result = await Navigator.push<List<String>>(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShippingDocumentsPage()),
              );
              if (result != null && context.mounted) {
                ref.read(dailyFormProvider.notifier).state = ref.read(dailyFormProvider).copyWith(
                      shippingDocuments: result
                          .map((d) => {'documentNumber': d})
                          .toList(),
                    );
              }
            },
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          // ========== Co-Driver (editable) ==========
          _buildFormRow(
            context,
            context.loc.coDriver,
            dashboard.coDriverName ?? '-',
            onEdit: () async {
              final coDriver = await showDialog<CoDriver>(
                context: context,
                builder: (_) => CoDriverPickerDialog(
                    currentCoDriverId: dashboard.coDriverId ?? 'none'),
              );
              if (coDriver != null && context.mounted) {
                ref
                    .read(dashboardDataProvider.notifier)
                    .updateCoDriver(coDriver);
                // Update form state with co-driver ID
                final coDriverIdInt = int.tryParse(coDriver.id);
                ref
                    .read(dailyFormProvider.notifier)
                    .setCoDriverId(coDriverIdInt);
              }
            },
          ),

          AppGap.xl,

          // ========== API Status Indicator ==========
          if (formState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          if (formState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                        formState.error!,
                        style: AppTextStyles(context)
                            .body
                            .copyWith(color: AppColors.dangerRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (formState.isSuccess)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.successGreen),
                    AppGap.hSm,
                    Text(
                      'Form saved successfully to server.',
                      style: AppTextStyles(context)
                          .body
                          .copyWith(color: AppColors.successGreen),
                    ),
                  ],
                ),
              ),
            ),

          // ========== SAVE Button — Atomic PUT to API ==========
          ElevatedButton(
            onPressed: formState.isSaving
                ? null
                : () async {
                    // SRS §5.13: Atomic Save — all form elements in ONE request
                    await ref
                        .read(dailyFormProvider.notifier)
                        .saveForm(selectedLog.id);

                    if (!context.mounted) return;

                    final state = ref.read(dailyFormProvider);
                    if (state.isSuccess) {
                      // Update local log state
                      final isComplete = dashboard.vehicleId.isNotEmpty;
                      final updatedLog =
                          selectedLog.copyWith(isFormComplete: isComplete);
                      ref.read(logsProvider.notifier).updateLog(updatedLog);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.loc.successMessage),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    } else if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error!),
                          backgroundColor: AppColors.dangerRed,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              elevation: 0,
            ),
            child: formState.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.surface),
                  )
                : Text(
                    context.loc.saveButton,
                    style: AppTextStyles(context)
                        .buttonText
                        .copyWith(color: AppColors.surface),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(BuildContext context, String title, String value,
      {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles(context).bodyBold,
                ),
                AppGap.xs,
                Text(
                  value,
                  style: AppTextStyles(context).body,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../vehicle/domain/entities/vehicle.dart';
import '../../widgets/vehicle_picker_dialog.dart';
import '../../widgets/codriver_picker_dialog.dart';
import '../../pages/trailers_page.dart';
import '../../pages/shipping_documents_page.dart';
import '../../providers/logs_provider.dart';

class FormTab extends ConsumerWidget {
  const FormTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormRow(context, context.loc.driver, dashboard.driverName),
          Divider(color: Theme.of(context).dividerColor, height: 1),
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
              }
            },
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          _buildFormRow(
            context,
            context.loc.trailers,
            dashboard.trailerId ?? '-',
            onEdit: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrailersPage()),
              );
            },
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          _buildFormRow(
            context,
            context.loc.shippingDocuments,
            dashboard.shippingDocuments ?? '-',
            onEdit: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShippingDocumentsPage()),
              );
            },
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),
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
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              final selectedLog = ref.read(logsProvider).selectedLog;
              if (selectedLog == null) return;

              // Check if form is complete (e.g. at least driver and vehicle are present)
              final isComplete = dashboard.vehicleId.isNotEmpty;

              final updatedLog =
                  selectedLog.copyWith(isFormComplete: isComplete);
              ref.read(logsProvider.notifier).updateLog(updatedLog);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.loc.successMessage),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              elevation: 0,
            ),
            child: Text(
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
                const SizedBox(height: 4),
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

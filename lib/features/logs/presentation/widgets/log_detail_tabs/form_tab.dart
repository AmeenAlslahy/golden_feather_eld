import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../backend/providers/backend_providers.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../vehicle/domain/entities/vehicle.dart';
import '../../../../vehicle/domain/vehicle_selection.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../domain/saved_form_status.dart';
import '../../pages/shipping_documents_page.dart';
import '../../pages/trailers_page.dart';
import '../../providers/logs_provider.dart';
import '../../widgets/codriver_picker_dialog.dart';
import '../../widgets/vehicle_picker_dialog.dart';

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
          AppButton(
            label: context.loc.saveButton.toUpperCase(),
            type: EldButtonType.agree,
            onPressed: () async {
              final selectedLog = ref.read(logsProvider).selectedLog;
              if (selectedLog == null) return;

              final form = _dailyFormPayload(
                dashboard,
                selectedLog.uniqueId,
              );
              if (form.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(form.error!),
                    backgroundColor: AppColors.dangerRed,
                  ),
                );
                return;
              }

              final saved = await ref.read(dailyLogsBackendProvider).saveForm(
                logId: selectedLog.id,
                form: form.body,
              );
              if (!context.mounted) return;
              saved.fold(
                (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.code),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                },
                (json) {
                  final read = readSavedForm(json);
                  if (read.complete != null) {
                    ref.read(logsProvider.notifier).updateLog(
                          selectedLog.copyWith(
                            isFormComplete: read.complete,
                            formStatus: read.complete!
                                ? FormStatus.completed
                                : FormStatus.incomplete,
                          ),
                        );
                  }
                  final arabic =
                      Localizations.localeOf(context).languageCode == 'ar';
                  final text = read.message ??
                      (read.complete == true
                          ? context.loc.successMessage
                          : read.complete == false
                              ? (arabic
                                  ? 'حفظ الخادم النموذج وتركه غير مكتمل.'
                                  : 'The server saved the form and left it incomplete.')
                              : (arabic
                                  ? 'حفظ الخادم النموذج ولم يُرجع حالة الاكتمال.'
                                  : 'The server saved the form but did not return a form status.'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(text),
                      backgroundColor: read.complete == false
                          ? AppColors.warningYellow
                          : AppColors.successGreen,
                    ),
                  );
                },
              );
            },
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
                  style: context.styles.bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: context.styles.body,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              splashColor: Colors.black26,
              highlightColor: Colors.black12,
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _DailyFormPayload {
  final Map<String, dynamic> body;
  final String? error;

  const _DailyFormPayload(this.body, this.error);
}

/// Builds `UpdateDailyFormRequest` from the live contract.
/// Arrays are objects, never bare strings. `coDriverId` is an integer or null.
_DailyFormPayload _dailyFormPayload(DashboardData dashboard, String logUniqueId) {
  final uniqueId = readOperableUniqueId(dashboard.vehicleId) ??
      readOperableUniqueId(logUniqueId) ??
      '';
  if (uniqueId.isEmpty) {
    return const _DailyFormPayload({}, 'Select a vehicle before saving the form.');
  }

  final trailers = <Map<String, String>>[];
  final trailer = dashboard.trailerId?.trim();
  if (trailer != null &&
      trailer.isNotEmpty &&
      trailer != 'None' &&
      trailer != '-') {
    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(trailer) || trailer.length > 50) {
      return const _DailyFormPayload(
        {},
        'Trailer number must be letters, numbers, or hyphens.',
      );
    }
    trailers.add({'trailerNumber': trailer});
  }

  final documents = <Map<String, String>>[];
  final document = dashboard.shippingDocuments?.trim();
  if (document != null &&
      document.isNotEmpty &&
      document != 'None' &&
      document != '-') {
    if (document.length > 100) {
      return const _DailyFormPayload({}, 'Shipping document number is too long.');
    }
    documents.add({'documentNumber': document});
  }

  int? coDriverId;
  final rawCoDriver = dashboard.coDriverId?.trim();
  if (rawCoDriver != null && rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
    coDriverId = int.tryParse(rawCoDriver);
    if (coDriverId == null) {
      return const _DailyFormPayload(
        {},
        'Co-driver must be a server id before it can be saved.',
      );
    }
  }

  return _DailyFormPayload({
    'uniqueId': uniqueId,
    'coDriverId': coDriverId,
    'trailers': trailers,
    'shippingDocuments': documents,
  }, null);
}

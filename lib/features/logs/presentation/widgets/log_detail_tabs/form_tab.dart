import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/error/user_facing_message.dart';
import '../../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../vehicle/domain/entities/vehicle.dart';
import '../../../../vehicle/domain/vehicle_selection.dart';
import '../../widgets/vehicle_picker_dialog.dart';
import '../../widgets/codriver_picker_dialog.dart';
import '../../pages/trailers_page.dart';
import '../../pages/shipping_documents_page.dart';
import '../../providers/logs_provider.dart';
import '../../../domain/daily_form_rules.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../domain/saved_form_status.dart';
import '../../../../../backend/providers/backend_providers.dart';
import '../../../../../core/widgets/app_feedback.dart';

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
                context.loc,
              );
              if (form.error != null) {
                AppFeedback.error(context, form.error!);
                return;
              }

              final saved = await ref.read(dailyLogsBackendProvider).saveForm(
                logId: selectedLog.id,
                form: form.body,
              );
              if (!context.mounted) return;
              saved.fold(
                (error) {
                  AppFeedback.error(context, anyErrorUserMessage(error, loc: AppLocalizations.of(context)!));
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
                  final text = read.message ??
                      (read.complete == true
                          ? context.loc.successMessage
                          : read.complete == false
                              ? context.loc.serverSavedFormIncomplete
                              : context.loc.serverSavedFormNoStatus);
                  AppFeedback.info(context, text);
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
              icon: Icon(Icons.edit, size: 18, color: context.styles.body.color),
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
_DailyFormPayload _dailyFormPayload(DashboardData dashboard, String logUniqueId, AppLocalizations loc) {
  final uniqueId = readOperableUniqueId(dashboard.vehicleId) ??
      readOperableUniqueId(logUniqueId) ??
      '';
  if (uniqueId.isEmpty) {
    return _DailyFormPayload(
      const {}, 
      loc.selectVehicleBeforeSavingForm,
    );
  }

  final trailers = <Map<String, String>>[];
  for (final trailer in splitFormList(dashboard.trailerId)) {
    final error = trailerNumberError(trailer, loc);
    if (error != null) return _DailyFormPayload(const {}, error);
    trailers.add({'trailerNumber': trailer});
  }

  final documents = <Map<String, String>>[];
  for (final document in splitFormList(dashboard.shippingDocuments)) {
    final error = shippingDocumentError(document, loc);
    if (error != null) return _DailyFormPayload(const {}, error);
    documents.add({'documentNumber': document});
  }

  int? coDriverId;
  final rawCoDriver = dashboard.coDriverId?.trim();
  if (rawCoDriver != null && rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
    coDriverId = int.tryParse(rawCoDriver);
    if (coDriverId == null) {
      return _DailyFormPayload(
        const {},
        loc.coDriverMustBeServerId,
      );
    }
  }

  return _DailyFormPayload({
    'uniqueId': uniqueId,
    if (coDriverId != null) 'coDriverId': coDriverId,
    'trailers': trailers,
    'shippingDocuments': documents,
  }, null);
}

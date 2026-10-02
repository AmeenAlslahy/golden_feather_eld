import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/log_repository_providers.dart';
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
import '../../../domain/entities/daily_form_update.dart';
import '../../../../../core/widgets/app_feedback.dart';

class FormTab extends ConsumerStatefulWidget {
  const FormTab({super.key});

  @override
  ConsumerState<FormTab> createState() => _FormTabState();
}

class _FormTabState extends ConsumerState<FormTab> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormRow(context, context.loc.driver, dashboard.driverName),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            FormField<String>(
              initialValue: dashboard.vehicleId,
              validator: (_) {
                final uniqueId =
                    readOperableUniqueId(dashboard.vehicleId) ??
                    readOperableUniqueId(
                      ref.read(logsProvider).selectedLog?.uniqueId ?? '',
                    ) ??
                    '';
                if (uniqueId.isEmpty) {
                  return context.loc.selectVehicleBeforeSavingForm;
                }
                return null;
              },
              builder: (field) => _buildFormRow(
                context,
                context.loc.vehicles,
                dashboard.vehicleDisplayName,
                errorText: field.errorText,
                onEdit: () async {
                  final vehicle = await showDialog<Vehicle>(
                    context: context,
                    builder: (_) => VehiclePickerDialog(
                      currentVehicleId: dashboard.vehicleId,
                    ),
                  );
                  if (vehicle != null && context.mounted) {
                    ref
                        .read(dashboardDataProvider.notifier)
                        .updateVehicle(vehicle);
                  }
                },
              ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            FormField<String>(
              initialValue: dashboard.trailerId,
              validator: (value) {
                for (final trailer in splitFormList(value)) {
                  final error = trailerNumberError(trailer, context.loc);
                  if (error != null) return error;
                }
                return null;
              },
              builder: (field) => _buildFormRow(
                context,
                context.loc.trailers,
                dashboard.trailerId ?? '-',
                errorText: field.errorText,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrailersPage()),
                  );
                },
              ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            FormField<String>(
              initialValue: dashboard.shippingDocuments,
              validator: (value) {
                for (final doc in splitFormList(value)) {
                  final error = shippingDocumentError(doc, context.loc);
                  if (error != null) return error;
                }
                return null;
              },
              builder: (field) => _buildFormRow(
                context,
                context.loc.shippingDocuments,
                dashboard.shippingDocuments ?? '-',
                errorText: field.errorText,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShippingDocumentsPage(),
                    ),
                  );
                },
              ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            FormField<String>(
              initialValue: dashboard.coDriverId,
              validator: (value) {
                final rawCoDriver = value?.trim();
                if (rawCoDriver != null &&
                    rawCoDriver.isNotEmpty &&
                    rawCoDriver != 'none') {
                  if (int.tryParse(rawCoDriver) == null) {
                    return context.loc.coDriverMustBeServerId;
                  }
                }
                return null;
              },
              builder: (field) => _buildFormRow(
                context,
                context.loc.coDriver,
                dashboard.coDriverName ?? '-',
                errorText: field.errorText,
                onEdit: () async {
                  final coDriver = await showDialog<CoDriver>(
                    context: context,
                    builder: (_) => CoDriverPickerDialog(
                      currentCoDriverId: dashboard.coDriverId ?? 'none',
                    ),
                  );
                  if (coDriver != null && context.mounted) {
                    ref
                        .read(dashboardDataProvider.notifier)
                        .updateCoDriver(coDriver);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.loc.saveButton.toUpperCase(),
              type: EldButtonType.agree,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final selectedLog = ref.read(logsProvider).selectedLog;
                if (selectedLog == null) return;

                final form = _dailyFormPayload(
                  dashboard,
                  selectedLog.uniqueId,
                  context.loc,
                );
                if (form.error != null) {
                  // Should be caught by form fields above, but fallback just in case
                  AppFeedback.error(context, form.error!);
                  return;
                }

                final saved = await ref
                    .read(logRepositoryProvider)
                    .saveForm(logId: selectedLog.id, form: form.update!);
                if (!context.mounted) return;
                saved.fold(
                  (error) {
                    AppFeedback.error(
                      context,
                      anyErrorUserMessage(
                        error,
                        loc: AppLocalizations.of(context)!,
                      ),
                    );
                  },
                  (result) {
                    if (result.isOffline) {
                      AppFeedback.success(
                        context,
                        context.loc.formSavedOffline,
                      );
                      return;
                    }

                    final read = result.syncedData!;
                    if (read.complete != null) {
                      ref
                          .read(logsProvider.notifier)
                          .updateLog(
                            selectedLog.copyWith(
                              isFormComplete: read.complete,
                              formStatus: read.complete!
                                  ? FormStatus.completed
                                  : FormStatus.incomplete,
                            ),
                          );
                    }
                    final text =
                        read.message ??
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
      ),
    );
  }

  Widget _buildFormRow(
    BuildContext context,
    String title,
    String value, {
    String? errorText,
    VoidCallback? onEdit,
  }) {
    final hasError = errorText != null;
    final errorColor = Theme.of(context).colorScheme.error;

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
                  style: context.styles.bodyBold.copyWith(
                    color: hasError ? errorColor : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: context.styles.body.copyWith(
                    color: hasError ? errorColor : null,
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      errorText,
                      style: context.styles.error.copyWith(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 18,
                color: context.styles.body.color,
              ),
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
  final DailyFormUpdate? update;
  final String? error;

  const _DailyFormPayload(this.update, this.error);
}

/// Builds `UpdateDailyFormRequest` from the live contract.
/// Arrays are objects, never bare strings. `coDriverId` is an integer or null.
_DailyFormPayload _dailyFormPayload(
  DashboardData dashboard,
  String logUniqueId,
  AppLocalizations loc,
) {
  final uniqueId =
      readOperableUniqueId(dashboard.vehicleId) ??
      readOperableUniqueId(logUniqueId) ??
      '';
  if (uniqueId.isEmpty) {
    return _DailyFormPayload(null, loc.selectVehicleBeforeSavingForm);
  }

  final trailers = <String>[];
  for (final trailer in splitFormList(dashboard.trailerId)) {
    final error = trailerNumberError(trailer, loc);
    if (error != null) return _DailyFormPayload(null, error);
    trailers.add(trailer);
  }

  final documents = <String>[];
  for (final document in splitFormList(dashboard.shippingDocuments)) {
    final error = shippingDocumentError(document, loc);
    if (error != null) return _DailyFormPayload(null, error);
    documents.add(document);
  }

  int? coDriverId;
  final rawCoDriver = dashboard.coDriverId?.trim();
  if (rawCoDriver != null && rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
    coDriverId = int.tryParse(rawCoDriver);
    if (coDriverId == null) {
      return _DailyFormPayload(null, loc.coDriverMustBeServerId);
    }
  }

  // SRS 5.13: عند غياب المساعد يُرسل coDriverId: null صراحةً — لا يُحذف
  // الحقل — والقوائم تُرسل [] حتى عند الفراغ.
  return _DailyFormPayload(
    DailyFormUpdate(
      vehicleUniqueId: uniqueId,
      coDriverId: coDriverId,
      trailers: trailers,
      shippingDocuments: documents,
    ),
    null,
  );
}

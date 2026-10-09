import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../vehicle/domain/entities/vehicle.dart';
import '../../../../vehicle/domain/vehicle_selection.dart';
import '../../controllers/form_tab_controller.dart';
import '../../widgets/vehicle_picker_dialog.dart';
import '../../widgets/codriver_picker_dialog.dart';
import '../../pages/trailers_page.dart';
import '../../pages/shipping_documents_page.dart';
import '../../providers/logs_provider.dart';
import '../../../domain/daily_form_rules.dart';
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
    final logsState = ref.watch(logsProvider);
    final selectedLog = logsState.selectedLog;
    final serverForm = logsState.serverForm;
    final dashboard = ref.watch(dashboardDataProvider);

    // استخراج القيم الفعلية المسترجعة من الخادم للسجل المحدد حالياً
    final driverDisplayName = (selectedLog?.driverName?.isNotEmpty == true)
        ? selectedLog!.driverName!
        : dashboard.driverName;

    final vehicleDisplayName = (serverForm?.vehicleName?.isNotEmpty == true)
        ? serverForm!.vehicleName!
        : ((selectedLog?.vehicleName?.isNotEmpty == true)
            ? selectedLog!.vehicleName!
            : dashboard.vehicleDisplayName);

    final vehicleUniqueId = (serverForm?.vehicleUniqueId?.isNotEmpty == true)
        ? serverForm!.vehicleUniqueId!
        : ((selectedLog?.uniqueId.isNotEmpty == true)
            ? selectedLog!.uniqueId
            : dashboard.vehicleId);

    final trailersDisplay = (serverForm?.trailers != null && serverForm!.trailers.isNotEmpty)
        ? joinFormList(serverForm.trailers)
        : ((selectedLog != null && selectedLog.trailers.isNotEmpty)
            ? joinFormList(selectedLog.trailers)
            : (dashboard.trailerId ?? '-'));

    final shippingDocsDisplay = (serverForm?.shippingDocuments != null && serverForm!.shippingDocuments.isNotEmpty)
        ? joinFormList(serverForm.shippingDocuments)
        : ((selectedLog != null && selectedLog.shippingDocuments.isNotEmpty)
            ? joinFormList(selectedLog.shippingDocuments)
            : (dashboard.shippingDocuments ?? '-'));

    final coDriverDisplayName = (serverForm?.coDriverName?.isNotEmpty == true)
        ? serverForm!.coDriverName!
        : (dashboard.coDriverName ?? '-');

    final coDriverIdValue = (serverForm?.coDriverId != null && serverForm!.coDriverId! > 0)
        ? '${serverForm.coDriverId}'
        : (dashboard.coDriverId ?? 'none');

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormRow(
              context,
              context.loc.driver,
              driverDisplayName,
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            FormField<String>(
              key: ValueKey('vehicle_${selectedLog?.id}_${serverForm?.vehicleUniqueId}_$vehicleUniqueId'),
              initialValue: vehicleUniqueId,
              validator: (_) {
                final uniqueId =
                    readOperableUniqueId(vehicleUniqueId) ??
                    readOperableUniqueId(
                      selectedLog?.uniqueId ?? '',
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
                vehicleDisplayName,
                errorText: field.errorText,
                onEdit: () async {
                  final vehicle = await showDialog<Vehicle>(
                    context: context,
                    builder: (_) => VehiclePickerDialog(
                      currentVehicleId: vehicleUniqueId,
                      allowCompanyFleet: false,
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
              key: ValueKey('trailers_${selectedLog?.id}_$trailersDisplay'),
              initialValue: trailersDisplay == '-' ? '' : trailersDisplay,
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
                trailersDisplay,
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
              key: ValueKey('shipping_${selectedLog?.id}_$shippingDocsDisplay'),
              initialValue: shippingDocsDisplay == '-' ? '' : shippingDocsDisplay,
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
                shippingDocsDisplay,
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
              key: ValueKey('codriver_${selectedLog?.id}_$coDriverIdValue'),
              initialValue: coDriverIdValue,
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
                coDriverDisplayName,
                errorText: field.errorText,
                onEdit: () async {
                  final coDriver = await showDialog<CoDriver>(
                    context: context,
                    builder: (_) => CoDriverPickerDialog(
                      currentCoDriverId: coDriverIdValue,
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
              type: EldButtonType.primary,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (selectedLog == null) return;
                
                final controller = ref.read(formTabControllerProvider(selectedLog).notifier);

                final form = _dailyFormPayload(
                  vehicleUniqueId: vehicleUniqueId,
                  trailersRaw: trailersDisplay == '-' ? '' : trailersDisplay,
                  shippingDocsRaw: shippingDocsDisplay == '-' ? '' : shippingDocsDisplay,
                  coDriverIdRaw: coDriverIdValue,
                  logUniqueId: selectedLog.uniqueId,
                  loc: context.loc,
                );
                if (form.error != null) {
                  AppFeedback.error(context, form.error!);
                  return;
                }

                final error = await controller.saveForm(
                  update: form.update!,
                  loc: context.loc,
                  onSuccess: (msg) {
                    if (context.mounted) AppFeedback.success(context, msg);
                  },
                  onOffline: (msg) {
                    if (context.mounted) AppFeedback.success(context, msg);
                  },
                );

                if (error != null && context.mounted) {
                  AppFeedback.error(context, error);
                }
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
_DailyFormPayload _dailyFormPayload({
  required String vehicleUniqueId,
  required String trailersRaw,
  required String shippingDocsRaw,
  required String coDriverIdRaw,
  required String logUniqueId,
  required AppLocalizations loc,
}) {
  final uniqueId =
      readOperableUniqueId(vehicleUniqueId) ??
      readOperableUniqueId(logUniqueId) ??
      '';
  if (uniqueId.isEmpty) {
    return _DailyFormPayload(null, loc.selectVehicleBeforeSavingForm);
  }

  final trailers = <String>[];
  for (final trailer in splitFormList(trailersRaw)) {
    final error = trailerNumberError(trailer, loc);
    if (error != null) return _DailyFormPayload(null, error);
    trailers.add(trailer);
  }

  final documents = <String>[];
  for (final document in splitFormList(shippingDocsRaw)) {
    final error = shippingDocumentError(document, loc);
    if (error != null) return _DailyFormPayload(null, error);
    documents.add(document);
  }

  int? coDriverId;
  final rawCoDriver = coDriverIdRaw.trim();
  if (rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
    coDriverId = int.tryParse(rawCoDriver);
    if (coDriverId == null) {
      return _DailyFormPayload(null, loc.coDriverMustBeServerId);
    }
  }

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../vehicle/domain/entities/vehicle.dart';
import '../../../domain/entities/daily_log.dart';
import '../../pages/shipping_documents_page.dart';
import '../../pages/trailers_page.dart';
import '../../providers/form_tab_provider.dart';
import '../../providers/logs_provider.dart';
import '../codriver_picker_dialog.dart';
import '../vehicle_picker_dialog.dart';

/// تبويب عرض وتعديل النموذج اليومي للسجل المختار (Daily Form).
///
/// واجهة عرض بحتة (Pure View): جميع قواعد التحقق من صحة البيانات، وتحديث
/// الحالة، وتجميع طلب الحفظ، مسندة إلى [FormTabData] و[FormTabNotifier].
class FormTab extends ConsumerStatefulWidget {
  const FormTab({super.key});

  @override
  ConsumerState<FormTab> createState() => _FormTabState();
}

class _FormTabState extends ConsumerState<FormTab> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final selectedLog = ref.watch(logsProvider).selectedLog;
    final formData = ref.watch(formTabDataProvider);
    final formState = selectedLog != null
        ? ref.watch(formTabProvider(selectedLog))
        : null;

    final divider = Divider(color: context.border, height: 1);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. اسم السائق (للقراءة فقط)
            _FormRow(
              title: context.loc.driver,
              value: formData.driverName,
            ),
            divider,

            // 2. المركبة
            _FormRow(
              key: ValueKey('vehicle_${selectedLog?.id}_${formData.vehicleUniqueId}'),
              title: context.loc.vehicles,
              value: formData.vehicleName,
              validator: (_) => formData.validateVehicle(
                context.loc,
                logUniqueId: selectedLog?.uniqueId,
              ),
              onEdit: () => _editVehicle(context, selectedLog, formData.vehicleUniqueId),
            ),
            divider,

            // 3. المقطورات
            _FormRow(
              key: ValueKey('trailers_${selectedLog?.id}_${formData.trailers}'),
              title: context.loc.trailers,
              value: formData.trailers,
              validator: (_) => formData.validateTrailers(context.loc),
              onEdit: () => _editTrailers(context),
            ),
            divider,

            // 4. وثائق الشحن
            _FormRow(
              key: ValueKey('shipping_${selectedLog?.id}_${formData.shippingDocuments}'),
              title: context.loc.shippingDocuments,
              value: formData.shippingDocuments,
              validator: (_) => formData.validateShippingDocuments(context.loc),
              onEdit: () => _editShippingDocuments(context),
            ),
            divider,

            // 5. السائق المساعد
            _FormRow(
              key: ValueKey('codriver_${selectedLog?.id}_${formData.coDriverId}'),
              title: context.loc.coDriver,
              value: formData.coDriverName,
              validator: (_) => formData.validateCoDriver(context.loc),
              onEdit: () => _editCoDriver(context, selectedLog, formData.coDriverId),
            ),
            const SizedBox(height: AppSpacing.xl),

            // زر الحفظ
            AppButton(
              label: context.loc.saveButton.toUpperCase(),
              type: EldButtonType.primary,
              isLoading: formState?.isLoading ?? false,
              onPressed: () => _handleSave(context, selectedLog),
            ),
          ],
        ),
      ),
    );
  }

  // ========== تفاعلات الواجهة والتنقل (UI Navigation & Dialog Interactions) ==========

  Future<void> _editVehicle(
    BuildContext context,
    DailyLog? selectedLog,
    String currentVehicleId,
  ) async {
    final vehicle = await showDialog<Vehicle>(
      context: context,
      builder: (_) => VehiclePickerDialog(
        currentVehicleId: currentVehicleId,
        allowCompanyFleet: false,
      ),
    );
    if (vehicle != null && selectedLog != null && context.mounted) {
      ref.read(formTabProvider(selectedLog).notifier).updateVehicle(vehicle);
    }
  }

  void _editTrailers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrailersPage()),
    );
  }

  void _editShippingDocuments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShippingDocumentsPage()),
    );
  }

  Future<void> _editCoDriver(
    BuildContext context,
    DailyLog? selectedLog,
    String currentCoDriverId,
  ) async {
    final coDriver = await showDialog<CoDriver>(
      context: context,
      builder: (_) => CoDriverPickerDialog(
        currentCoDriverId: currentCoDriverId,
      ),
    );
    if (coDriver != null && selectedLog != null && context.mounted) {
      ref.read(formTabProvider(selectedLog).notifier).updateCoDriver(coDriver);
    }
  }

  // ========== إجراء حفظ النموذج عبر Notifier ==========

  Future<void> _handleSave(
    BuildContext context,
    DailyLog? selectedLog,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLog == null) return;

    final error = await ref
        .read(formTabProvider(selectedLog).notifier)
        .submitForm(
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
  }
}

/// صف عرض عنصر من عناصر النموذج اليومي متكامل مع التحقق وحالة الحقل.
class _FormRow extends FormField<String> {
  _FormRow({
    super.key,
    required String title,
    required String value,
    super.validator,
    VoidCallback? onEdit,
  }) : super(
          initialValue: value,
          builder: (field) {
            final context = field.context;
            final hasError = field.hasError;
            final errorColor = context.colors.error;

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
                              field.errorText!,
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
          },
        );
}

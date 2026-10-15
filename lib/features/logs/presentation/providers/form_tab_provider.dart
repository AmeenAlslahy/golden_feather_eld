import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../data/providers/log_repository_providers.dart';
import 'logs_provider.dart';
import '../../domain/daily_form_rules.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/daily_form_update.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../codriver/domain/entities/codriver.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/domain/vehicle_selection.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

/// حالة واجهة تبويب النموذج اليومي.
class FormTabState {
  final bool isLoading;
  const FormTabState({this.isLoading = false});
}

/// البيانات المعروضة في تبويب النموذج، بعد معالجة أسبقية المصادر بسلاسة.
class FormTabData {
  final String driverName;
  final String vehicleName;
  final String vehicleUniqueId;
  final String trailers;
  final String shippingDocuments;
  final String coDriverName;
  final String coDriverId;

  const FormTabData({
    required this.driverName,
    required this.vehicleName,
    required this.vehicleUniqueId,
    required this.trailers,
    required this.shippingDocuments,
    required this.coDriverName,
    required this.coDriverId,
  });

  /// التحقق من صحة المركبة قبل الحفظ
  String? validateVehicle(AppLocalizations loc, {String? logUniqueId}) {
    final uniqueId = readOperableUniqueId(vehicleUniqueId) ??
        readOperableUniqueId(logUniqueId ?? '') ??
        '';
    if (uniqueId.isEmpty) {
      return loc.selectVehicleBeforeSavingForm;
    }
    return null;
  }

  /// التحقق من صحة أرقام المقطورات
  String? validateTrailers(AppLocalizations loc) {
    final raw = trailers == '-' ? '' : trailers;
    for (final trailer in splitFormList(raw)) {
      final error = trailerNumberError(trailer, loc);
      if (error != null) return error;
    }
    return null;
  }

  /// التحقق من صحة وثائق الشحن
  String? validateShippingDocuments(AppLocalizations loc) {
    final raw = shippingDocuments == '-' ? '' : shippingDocuments;
    for (final doc in splitFormList(raw)) {
      final error = shippingDocumentError(doc, loc);
      if (error != null) return error;
    }
    return null;
  }

  /// التحقق من صحة السائق المساعد
  String? validateCoDriver(AppLocalizations loc) {
    final raw = coDriverId.trim();
    if (raw.isNotEmpty && raw != 'none') {
      if (int.tryParse(raw) == null) {
        return loc.coDriverMustBeServerId;
      }
    }
    return null;
  }

  /// تحويل البيانات المعروضة إلى كائن التحديث المطلوب إرساله إلى الخادم
  DailyFormUpdate toDailyFormUpdate({required String fallbackLogUniqueId}) {
    final uniqueId = readOperableUniqueId(vehicleUniqueId) ??
        readOperableUniqueId(fallbackLogUniqueId) ??
        '';

    final parsedTrailers = splitFormList(trailers == '-' ? '' : trailers);
    final parsedDocs = splitFormList(
      shippingDocuments == '-' ? '' : shippingDocuments,
    );

    int? parsedCoDriverId;
    final rawCoDriver = coDriverId.trim();
    if (rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
      parsedCoDriverId = int.tryParse(rawCoDriver);
    }

    return DailyFormUpdate(
      vehicleUniqueId: uniqueId,
      coDriverId: parsedCoDriverId,
      trailers: parsedTrailers,
      shippingDocuments: parsedDocs,
    );
  }
}

/// موفر يستخرج بيانات تبويب النموذج ويوحد مصادر الحقيقة دون تشتت أو تعقيد في طبقة العرض.
final formTabDataProvider = Provider.autoDispose<FormTabData>((ref) {
  final logsState = ref.watch(logsProvider);
  final selectedLog = logsState.selectedLog;
  final serverForm = logsState.serverForm;
  final dashboard = ref.watch(dashboardDataProvider);

  // 1. اسم السائق
  final driverName = (selectedLog?.driverName?.isNotEmpty == true)
      ? selectedLog!.driverName!
      : dashboard.driverName;

  // 2. اسم المركبة والمعرف الفريد: الأولوية للحالة الحية في Dashboard إذا تم تعديلها
  final vName = (dashboard.vehicleDisplayName != 'Select a vehicle' &&
          dashboard.vehicleDisplayName.isNotEmpty)
      ? dashboard.vehicleDisplayName
      : (serverForm?.vehicleName?.isNotEmpty == true
          ? serverForm!.vehicleName!
          : (selectedLog?.vehicleName?.isNotEmpty == true
              ? selectedLog!.vehicleName!
              : dashboard.vehicleDisplayName));

  final vId = (dashboard.vehicleId != 'No Vehicle' &&
          dashboard.vehicleId.isNotEmpty)
      ? dashboard.vehicleId
      : (serverForm?.vehicleUniqueId?.isNotEmpty == true
          ? serverForm!.vehicleUniqueId!
          : (selectedLog?.uniqueId.isNotEmpty == true
              ? selectedLog!.uniqueId
              : dashboard.vehicleId));

  // 3. المقطورات: الأولوية للقيمة المعدلة الحية، ثم نموذج الخادم، ثم السجل
  final trailers = (dashboard.trailerId != null &&
          dashboard.trailerId != 'None' &&
          dashboard.trailerId!.isNotEmpty)
      ? dashboard.trailerId!
      : (serverForm?.trailers.isNotEmpty == true
          ? joinFormList(serverForm!.trailers)
          : (selectedLog?.trailers.isNotEmpty == true
              ? joinFormList(selectedLog!.trailers)
              : '-'));

  // 4. وثائق الشحن: الأولوية للقيمة المعدلة الحية، ثم نموذج الخادم، ثم السجل
  final docs = (dashboard.shippingDocuments != null &&
          dashboard.shippingDocuments != 'None' &&
          dashboard.shippingDocuments!.isNotEmpty)
      ? dashboard.shippingDocuments!
      : (serverForm?.shippingDocuments.isNotEmpty == true
          ? joinFormList(serverForm!.shippingDocuments)
          : (selectedLog?.shippingDocuments.isNotEmpty == true
              ? joinFormList(selectedLog!.shippingDocuments)
              : '-'));

  // 5. السائق المساعد
  final coDriverName = (dashboard.coDriverName?.isNotEmpty == true)
      ? dashboard.coDriverName!
      : (serverForm?.coDriverName?.isNotEmpty == true
          ? serverForm!.coDriverName!
          : '-');

  final coDriverId = (dashboard.coDriverId?.isNotEmpty == true &&
          dashboard.coDriverId != 'none')
      ? dashboard.coDriverId!
      : ((serverForm?.coDriverId != null && serverForm!.coDriverId! > 0)
          ? '${serverForm.coDriverId}'
          : 'none');

  return FormTabData(
    driverName: driverName,
    vehicleName: vName,
    vehicleUniqueId: vId,
    trailers: trailers,
    shippingDocuments: docs,
    coDriverName: coDriverName,
    coDriverId: coDriverId,
  );
});

class FormTabNotifier extends StateNotifier<FormTabState> {
  final Ref _ref;
  final DailyLog _log;

  FormTabNotifier(this._ref, this._log) : super(const FormTabState());

  /// تحديث المركبة المختارة في حالة لوحة القيادة
  void updateVehicle(Vehicle vehicle) {
    _ref.read(dashboardDataProvider.notifier).updateVehicle(vehicle);
  }

  /// تحديث السائق المساعد المختار في حالة لوحة القيادة
  void updateCoDriver(CoDriver coDriver) {
    _ref.read(dashboardDataProvider.notifier).updateCoDriver(coDriver);
  }

  /// إرسال النموذج بعد تجميعه والتحقق من صحة كافة الحقول
  Future<String?> submitForm({
    required AppLocalizations loc,
    required void Function(String) onSuccess,
    required void Function(String) onOffline,
  }) async {
    final formData = _ref.read(formTabDataProvider);

    final vehicleErr = formData.validateVehicle(loc, logUniqueId: _log.uniqueId);
    if (vehicleErr != null) return vehicleErr;

    final trailerErr = formData.validateTrailers(loc);
    if (trailerErr != null) return trailerErr;

    final docErr = formData.validateShippingDocuments(loc);
    if (docErr != null) return docErr;

    final coDriverErr = formData.validateCoDriver(loc);
    if (coDriverErr != null) return coDriverErr;

    final update = formData.toDailyFormUpdate(
      fallbackLogUniqueId: _log.uniqueId,
    );
    return saveForm(
      update: update,
      loc: loc,
      onSuccess: onSuccess,
      onOffline: onOffline,
    );
  }

  Future<String?> saveForm({
    required DailyFormUpdate update,
    required AppLocalizations loc,
    required void Function(String) onSuccess,
    required void Function(String) onOffline,
  }) async {
    state = const FormTabState(isLoading: true);
    
    // P0 2B-1 — ربط المالك المثبت من الجلسة
    final result = await _ref.read(logRepositoryProvider).saveForm(
      logId: _log.id,
      form: update,
      ownerDriverId: _ref.read(currentDriverIdProvider),
    );
    
    if (!mounted) return null;
    state = const FormTabState(isLoading: false);
    
    return result.fold(
      (error) => anyErrorUserMessage(error, loc: loc),
      (saveResult) {
        final hasVehicle = update.vehicleUniqueId.isNotEmpty;
        final hasDocs = update.shippingDocuments.isNotEmpty;
        final isLocallyComplete = hasVehicle && hasDocs;

        if (saveResult.isOffline) {
          _ref.read(logsProvider.notifier).updateLog(
            _log.copyWith(
              uniqueId: update.vehicleUniqueId,
              trailers: update.trailers,
              shippingDocuments: update.shippingDocuments,
              isFormComplete: isLocallyComplete,
              formStatus: isLocallyComplete ? FormStatus.completed : FormStatus.incomplete,
            ),
          );
          onOffline(loc.formSavedOffline);
          return null;
        }

        final read = saveResult.syncedData!;
        final complete = read.complete ?? isLocallyComplete;
        _ref.read(logsProvider.notifier).updateLog(
          _log.copyWith(
            uniqueId: update.vehicleUniqueId,
            trailers: update.trailers,
            shippingDocuments: update.shippingDocuments,
            isFormComplete: complete,
            formStatus: complete ? FormStatus.completed : FormStatus.incomplete,
          ),
        );
        
        final msg = complete
            ? loc.successMessage
            : loc.serverSavedFormIncomplete;
        onSuccess(msg);
        return null;
      }
    );
  }
}

/// موفر تبويب النموذج اليومي
final formTabProvider = StateNotifierProvider.autoDispose.family<FormTabNotifier, FormTabState, DailyLog>((ref, log) {
  return FormTabNotifier(ref, log);
});

/// اسم بديل للتوافق البرمجي الكامل مع الكود القائم
final formTabControllerProvider = formTabProvider;
typedef FormTabController = FormTabNotifier;

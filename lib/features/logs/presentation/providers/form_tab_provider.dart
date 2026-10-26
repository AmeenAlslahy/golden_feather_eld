import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../data/providers/log_repository_providers.dart';
import 'logs_provider.dart';
import '../../domain/daily_form_rules.dart';
import '../mappers/form_validation_mapper.dart';
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
    final uniqueId =
        readOperableUniqueId(vehicleUniqueId) ??
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
    final uniqueId =
        readOperableUniqueId(vehicleUniqueId) ??
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
/// قيمة غير فارغة أو null — مع استبعاد عوامل العرض ('Select a vehicle'
/// / 'No Vehicle' / 'None') حيث كانت تُستثنى في السلاسل الأصلية.
String? _meaningful(String? value, {Set<String>? exclude}) {
  final v = value ?? '';
  if (v.isEmpty) return null;
  if (exclude != null && exclude.contains(v)) return null;
  return v;
}

/// أول قيمة غير فارغة من المرشحين بالترتيب (الترتيب = الأولوية:
/// قيمة حية ← نموذج الخادم ← صف السجل)، و[fallback] عند فراغ الجميع.
String _firstOf(List<String?> candidates, {String fallback = ''}) {
  for (final candidate in candidates) {
    final value = _meaningful(candidate);
    if (value != null) return value;
  }
  return fallback;
}

const _placeholderVehicleSentinel = {'Select a vehicle'};
const _noVehicleSentinel = {'No Vehicle'};
const _noneSentinel = {'None'};

/// موفر يستخرج بيانات تبويب النموذج ويوحد مصادر الحقيقة — كل حقل سلسلة
/// أولويات معلنة بمساعد نقّي واحد بدل شلال ternaries متشعب (مراجعة
/// 2026-10-25)؛ الترتيب والدلالات كما كانت حرفياً.
final formTabDataProvider = Provider.autoDispose<FormTabData>((ref) {
  final logsState = ref.watch(logsProvider);
  final selectedLog = logsState.selectedLog;
  final serverForm = logsState.serverForm;
  final dashboard = ref.watch(dashboardDataProvider);

  // حالة اللوحة الحية تخص سجل اليوم الحالي حصراً؛ أي سجل سابق يقرأ قيمه
  // المحفوظة الخاصة به (نموذج الخادم ثم صف السجل) كي لا تتسرب قيم يوم
  // إلى يوم آخر.
  final liveDashboard = selectedLog == null || selectedLog.today;

  // 1. اسم السائق
  final driverName = _firstOf([selectedLog?.driverName, dashboard.driverName]);

  // 2. اسم المركبة والمعرف الفريد: الأولوية للحالة الحية في Dashboard إذا
  // تم تعديلها — لسجل اليوم فقط.
  final vName = liveDashboard
      ? _firstOf([
          _meaningful(
            dashboard.vehicleDisplayName,
            exclude: _placeholderVehicleSentinel,
          ),
          serverForm?.vehicleName,
          selectedLog?.vehicleName,
        ], fallback: dashboard.vehicleDisplayName)
      : _firstOf([
          serverForm?.vehicleName,
          selectedLog.vehicleName,
          selectedLog.uniqueId,
        ], fallback: '-');

  final vId = liveDashboard
      ? _firstOf([
          _meaningful(dashboard.vehicleId, exclude: _noVehicleSentinel),
          serverForm?.vehicleUniqueId,
          selectedLog?.uniqueId,
        ], fallback: dashboard.vehicleId)
      : _firstOf([serverForm?.vehicleUniqueId, selectedLog.uniqueId]);

  // 3. المقطورات: الأولوية للقيمة المعدلة الحية (سجل اليوم)، ثم نموذج
  // الخادم، ثم صف السجل
  final liveTrailers = _meaningful(dashboard.trailerId, exclude: _noneSentinel);
  final trailers = liveDashboard && liveTrailers != null
      ? liveTrailers
      : _firstOf([
          if (serverForm?.trailers.isNotEmpty == true)
            joinFormList(serverForm!.trailers),
          if (selectedLog?.trailers.isNotEmpty == true)
            joinFormList(selectedLog!.trailers),
        ], fallback: '-');

  // 4. وثائق الشحن: الأولوية للقيمة المعدلة الحية (سجل اليوم)، ثم نموذج
  // الخادم، ثم صف السجل
  final liveDocs = _meaningful(
    dashboard.shippingDocuments,
    exclude: _noneSentinel,
  );
  final docs = liveDashboard && liveDocs != null
      ? liveDocs
      : _firstOf([
          if (serverForm?.shippingDocuments.isNotEmpty == true)
            joinFormList(serverForm!.shippingDocuments),
          if (selectedLog?.shippingDocuments.isNotEmpty == true)
            joinFormList(selectedLog!.shippingDocuments),
        ], fallback: '-');

  // 5. السائق المساعد
  final coDriverName = liveDashboard
      ? _firstOf([
          dashboard.coDriverName,
          serverForm?.coDriverName,
        ], fallback: '-')
      : _firstOf([serverForm?.coDriverName], fallback: '-');

  final coDriverId =
      (liveDashboard &&
          _meaningful(dashboard.coDriverId, exclude: _noneSentinel) != null)
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

  /// الحالة الحية (لوحة القيادة) تخص سجل اليوم حصراً؛ أي سجل سابق يكتب
  /// اختياره على نموذج السجل نفسه كي لا تتسرب قيم يوم إلى يوم آخر.
  bool get _isLiveDashboard {
    final selected = _ref.read(logsProvider).selectedLog;
    return selected == null || selected.today;
  }

  /// تحديث المركبة المختارة: الحالة الحية لسجل اليوم، أو نموذج السجل.
  void updateVehicle(Vehicle vehicle) {
    if (!_isLiveDashboard) {
      _ref
          .read(logsProvider.notifier)
          .updateSelectedFormVehicle(
            vehicleId: int.tryParse(vehicle.id),
            vehicleUniqueId: vehicle.uniqueId ?? vehicle.id,
            vehicleName: vehicle.displayName,
          );
      return;
    }
    _ref.read(dashboardDataProvider.notifier).updateVehicle(vehicle);
  }

  /// تحديث السائق المساعد: الحالة الحية لسجل اليوم، أو نموذج السجل.
  void updateCoDriver(CoDriver coDriver) {
    if (!_isLiveDashboard) {
      _ref
          .read(logsProvider.notifier)
          .updateSelectedFormCoDriver(
            coDriverId: int.tryParse(coDriver.id),
            coDriverName: coDriver.name,
          );
      return;
    }
    _ref.read(dashboardDataProvider.notifier).updateCoDriver(coDriver);
  }

  /// إرسال النموذج بعد تجميعه والتحقق من صحة كافة الحقول
  Future<String?> submitForm({
    required AppLocalizations loc,
    required void Function(String) onSuccess,
    required void Function(String) onOffline,
  }) async {
    final formData = _ref.read(formTabDataProvider);

    final vehicleErr = formData.validateVehicle(
      loc,
      logUniqueId: _log.uniqueId,
    );
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
    final result = await _ref
        .read(logRepositoryProvider)
        .saveForm(
          logId: _log.id,
          form: update,
          ownerDriverId: _ref.read(currentDriverIdProvider),
        );

    if (!mounted) return null;
    state = const FormTabState(isLoading: false);

    return result.fold((error) => anyErrorUserMessage(error, loc: loc), (
      saveResult,
    ) {
      final hasVehicle = update.vehicleUniqueId.isNotEmpty;
      final hasDocs = update.shippingDocuments.isNotEmpty;
      final isLocallyComplete = hasVehicle && hasDocs;

      if (saveResult.isOffline) {
        _ref
            .read(logsProvider.notifier)
            .updateLog(
              _log.copyWith(
                uniqueId: update.vehicleUniqueId,
                trailers: update.trailers,
                shippingDocuments: update.shippingDocuments,
                isFormComplete: isLocallyComplete,
                formStatus: isLocallyComplete
                    ? FormStatus.completed
                    : FormStatus.incomplete,
              ),
            );
        onOffline(loc.formSavedOffline);
        return null;
      }

      final read = saveResult.syncedData!;
      final complete = read.complete ?? isLocallyComplete;
      _ref
          .read(logsProvider.notifier)
          .updateLog(
            _log.copyWith(
              uniqueId: update.vehicleUniqueId,
              trailers: update.trailers,
              shippingDocuments: update.shippingDocuments,
              isFormComplete: complete,
              formStatus: complete
                  ? FormStatus.completed
                  : FormStatus.incomplete,
            ),
          );

      final msg = complete ? loc.successMessage : loc.serverSavedFormIncomplete;
      onSuccess(msg);
      return null;
    });
  }
}

/// موفر تبويب النموذج اليومي
final formTabProvider = StateNotifierProvider.autoDispose
    .family<FormTabNotifier, FormTabState, DailyLog>((ref, log) {
      return FormTabNotifier(ref, log);
    });

/// اسم بديل للتوافق البرمجي الكامل مع الكود القائم
final formTabControllerProvider = formTabProvider;
typedef FormTabController = FormTabNotifier;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../data/providers/log_repository_providers.dart';
import 'form_list_provider.dart';
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
  DailyFormUpdate toDailyFormUpdate({
    required String fallbackLogUniqueId,
    int? vehicleId,
  }) {
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
      vehicleId: vehicleId,
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

  // 3. المقطورات: القيمة الحية (سجل اليوم) ← نموذج الخادم ← صف السجل.
  // نفس دالة الأسبقية التي تستخدمها شاشة المقطورات، فلا تختلف القيمة
  // المعروضة عن مصدر الحفظ.
  final trailerItems = resolveFormListItems(
    logsState: logsState,
    liveItems: splitFormList(dashboard.trailerId),
    fromServerForm: (form) => form.trailers,
    fromLogRow: (log) => log.trailers,
  );
  final trailers = trailerItems.isEmpty ? '-' : joinFormList(trailerItems);

  // 4. وثائق الشحن: نفس أسبقية المقطورات حرفياً.
  final documentItems = resolveFormListItems(
    logsState: logsState,
    liveItems: splitFormList(dashboard.shippingDocuments),
    fromServerForm: (form) => form.shippingDocuments,
    fromLogRow: (log) => log.shippingDocuments,
  );
  final docs = documentItems.isEmpty ? '-' : joinFormList(documentItems);

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
  final DailyLogId _logId;

  FormTabNotifier(this._ref, this._logId) : super(const FormTabState());

  /// السجل المحفوظ لمعرّف التبويب، يُقرأ طازجاً من المزود حتى لا تتجمد
  /// نسخة قديمة بعد حفظ/تحديث السجل. المفتاح معرّف فقط كي لا يُعاد بناء
  /// الـ notifier مع كل تغيير في حقول السجل.
  DailyLog? _currentLog() {
    final state = _ref.read(logsProvider);
    final selected = state.selectedLog;
    if (selected != null && selected.id == _logId) return selected;
    for (final log in state.logs) {
      if (log.id == _logId) return log;
    }
    return null;
  }

  /// الحالة الحية (لوحة القيادة) تخص سجل اليوم حصراً؛ أي سجل سابق يكتب
  /// اختياره على نموذج السجل نفسه كي لا تتسرب قيم يوم إلى يوم آخر.
  bool get _isLiveDashboard => _currentLog()?.today ?? true;

  /// تحديث المركبة المختارة: الحالة الحية لسجل اليوم، أو نموذج السجل.
  void updateVehicle(Vehicle vehicle) {
    if (!_isLiveDashboard) {
      // `Vehicle.id` قد يكون `uniqueId` نصياً وليس معرّف قائمة رقمياً؛
      // تحويله إلى int كان يخترع `vehicleId`. نرسل `uniqueId` فقط،
      // و`submitForm` يحذف `vehicleId` القديم عند تغيّر المركبة.
      _ref
          .read(logsProvider.notifier)
          .updateSelectedFormVehicle(
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
    final logUniqueId = _currentLog()?.uniqueId;

    final vehicleErr = formData.validateVehicle(loc, logUniqueId: logUniqueId);
    if (vehicleErr != null) return vehicleErr;

    final trailerErr = formData.validateTrailers(loc);
    if (trailerErr != null) return trailerErr;

    final docErr = formData.validateShippingDocuments(loc);
    if (docErr != null) return docErr;

    final coDriverErr = formData.validateCoDriver(loc);
    if (coDriverErr != null) return coDriverErr;

    final serverForm = _ref.read(logsProvider).serverForm;
    // `vehicleId` الرقمي يخص المركبة القديمة في نموذج الخادم. عند تغيير
    // المركبة لا يجوز إرساله مع `uniqueId` الجديد؛ نحتفظ به فقط إذا كانت
    // المركبة المختارة هي نفسها.
    final selectedUniqueId = formData.vehicleUniqueId.trim();
    final sameVehicle = serverForm?.vehicleUniqueId?.trim() == selectedUniqueId;
    final update = formData.toDailyFormUpdate(
      fallbackLogUniqueId: logUniqueId ?? '',
      vehicleId: sameVehicle ? serverForm?.vehicleId : null,
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
    final log = _currentLog();
    if (log == null) return loc.noData;

    state = const FormTabState(isLoading: true);

    // P0 2B-1 — ربط المالك المثبت من الجلسة
    final result = await _ref
        .read(logRepositoryProvider)
        .saveForm(
          logId: _logId,
          form: update,
          ownerDriverId: _ref.read(currentDriverIdProvider),
        );

    if (!mounted) return null;
    state = const FormTabState(isLoading: false);

    return result.fold((error) => anyErrorUserMessage(error, loc: loc), (
      saveResult,
    ) {
      if (saveResult.isOffline) {
        // البيانات محفوظة والطلب في الطابور، لكن الخادم لم يؤكد الاكتمال.
        _ref
            .read(logsProvider.notifier)
            .updateLog(
              log.copyWith(
                uniqueId: update.vehicleUniqueId,
                trailers: update.trailers,
                shippingDocuments: update.shippingDocuments,
                isFormComplete: false,
                formStatus: FormStatus.pendingSync,
              ),
            );
        onOffline(loc.formSavedOffline);
        return null;
      }

      final read = saveResult.syncedData!;
      // `null` يعني أن الخادم لم يرسل حالة اكتمال. لا نستبدلها بحساب
      // محلي كأنه تأكيد؛ نحتفظ بالحالة السابقة ونعرض نجاح الحفظ فقط.
      final complete = read.complete;
      final isComplete = complete ?? log.isFormComplete;
      final status = complete == null
          ? log.formStatus
          : (complete ? FormStatus.completed : FormStatus.incomplete);
      _ref
          .read(logsProvider.notifier)
          .updateLog(
            log.copyWith(
              uniqueId: update.vehicleUniqueId,
              trailers: update.trailers,
              shippingDocuments: update.shippingDocuments,
              isFormComplete: isComplete,
              formStatus: status,
            ),
          );

      final serverMsg = read.message;
      final msg = (serverMsg != null && serverMsg.trim().isNotEmpty)
          ? serverMsg.trim()
          : (complete == false
              ? loc.serverSavedFormIncomplete
              : loc.successMessage);
      onSuccess(msg);
      return null;
    });
  }
}

/// موفر تبويب النموذج اليومي — المفتاح معرّف السجل فقط، لا نسخة
/// [DailyLog] كاملة، كي لا يُعاد بناء/تصفير التبويب عند كل تحديث للحقول.
final formTabProvider = StateNotifierProvider.autoDispose
    .family<FormTabNotifier, FormTabState, DailyLogId>((ref, logId) {
      return FormTabNotifier(ref, logId);
    });

/// اسم بديل للتوافق البرمجي الكامل مع الكود القائم
final formTabControllerProvider = formTabProvider;
typedef FormTabController = FormTabNotifier;

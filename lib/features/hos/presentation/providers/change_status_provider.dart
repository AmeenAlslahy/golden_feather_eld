import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/entities/hos_models.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../domain/account/driver_rules.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../account/presentation/providers/driver_rules_provider.dart';
import '../../../tracking/domain/entities/location_entity.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/engine/hos_offline_dashboard.dart';
import 'hos_engine_provider.dart';
import 'hos_provider.dart';
import 'status_dashboard_providers.dart';

/// نص موقع GPS الحقيقي لنموذج تغيير الحالة — '' تعني «لا موقع موثوق»
/// (لا قراءة، أو إحداثيات صفرية افتراضية بلا قفل فعلي).
String gpsLocationText(LocationEntity? location) {
  if (location == null) return '';
  if (location.latitude == 0 && location.longitude == 0) return '';
  return location.coordinates;
}

/// خيارات حالة الخدمة المتاحة في الواجهة كاختيارات راديو حصرية
enum DutyStatusOption {
  offDuty,
  sleeperBerth,
  driving,
  onDuty,
  yardMoves,
  personalConveyance;

  DutyStatus toDutyStatus() {
    switch (this) {
      case DutyStatusOption.offDuty:
        return DutyStatus.offDuty;
      case DutyStatusOption.sleeperBerth:
        return DutyStatus.sleeperBerth;
      case DutyStatusOption.driving:
        return DutyStatus.driving;
      case DutyStatusOption.onDuty:
      case DutyStatusOption.yardMoves:
        return DutyStatus.onDutyNotDriving;
      case DutyStatusOption.personalConveyance:
        return DutyStatus.personalUse;
    }
  }

  DutyStatusCode toDutyStatusCode() {
    switch (this) {
      case DutyStatusOption.offDuty:
        return DutyStatusCode.offDuty;
      case DutyStatusOption.sleeperBerth:
        return DutyStatusCode.sleeperBerth;
      case DutyStatusOption.driving:
        return DutyStatusCode.driving;
      case DutyStatusOption.onDuty:
        return DutyStatusCode.onDutyNotDriving;
      case DutyStatusOption.yardMoves:
        return DutyStatusCode.yardMove;
      case DutyStatusOption.personalConveyance:
        return DutyStatusCode.personalConveyance;
    }
  }

  bool get isYardMoves => this == DutyStatusOption.yardMoves;

  String displayName(BuildContext context) {
    final loc = context.loc;
    switch (this) {
      case DutyStatusOption.offDuty:
        return loc.offDuty;
      case DutyStatusOption.sleeperBerth:
        return loc.localeName == 'en' ? 'Sleeper' : loc.sleeperBerth;
      case DutyStatusOption.driving:
        return loc.drivingStatus;
      case DutyStatusOption.onDuty:
        return loc.onDuty;
      case DutyStatusOption.yardMoves:
        return loc.yardMoves;
      case DutyStatusOption.personalConveyance:
        return loc.personalUse;
    }
  }

  static DutyStatusOption fromCurrent({
    required DutyStatus status,
    required bool isYardMoves,
  }) {
    if (isYardMoves && status == DutyStatus.onDutyNotDriving) {
      return DutyStatusOption.yardMoves;
    }
    switch (status) {
      case DutyStatus.offDuty:
        return DutyStatusOption.offDuty;
      case DutyStatus.sleeperBerth:
        return DutyStatusOption.sleeperBerth;
      case DutyStatus.driving:
        return DutyStatusOption.driving;
      case DutyStatus.onDutyNotDriving:
        return DutyStatusOption.onDuty;
      case DutyStatus.personalUse:
        return DutyStatusOption.personalConveyance;
    }
  }

  static DutyStatusOption fromStatusCode(DutyStatusCode code) {
    switch (code) {
      case DutyStatusCode.offDuty:
        return DutyStatusOption.offDuty;
      case DutyStatusCode.sleeperBerth:
        return DutyStatusOption.sleeperBerth;
      case DutyStatusCode.driving:
        return DutyStatusOption.driving;
      case DutyStatusCode.onDutyNotDriving:
        return DutyStatusOption.onDuty;
      case DutyStatusCode.yardMove:
        return DutyStatusOption.yardMoves;
      case DutyStatusCode.personalConveyance:
        return DutyStatusOption.personalConveyance;
    }
  }
}

/// تمثيل نمطي صريح لنتائج تغيير واجب السائق دون سلاسل نصية سحرية
sealed class DutyChangeResult {
  const DutyChangeResult();
}

class DutyChangeSuccess extends DutyChangeResult {
  const DutyChangeSuccess();
}

class DutyChangeAlreadyInProgress extends DutyChangeResult {
  const DutyChangeAlreadyInProgress();
}

class DutyChangeAnnotationRequired extends DutyChangeResult {
  const DutyChangeAnnotationRequired();
}

class DutyChangeVehicleMoving extends DutyChangeResult {
  const DutyChangeVehicleMoving();
}

class DutyChangeEngineRefusal extends DutyChangeResult {
  final String reason;
  const DutyChangeEngineRefusal(this.reason);
}

/// كائن الحالة النقي لنموذج تغيير حالة السائق
class ChangeStatusState {
  final DutyStatusOption initialOption;
  final DutyStatusOption selectedOption;
  final String location;
  final String customLocation;
  final String notes;
  final bool isPersonalConveyanceAllowed;
  final bool isYardMoveAllowed;
  final bool isVehicleMoving;
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  const ChangeStatusState({
    required this.initialOption,
    required this.selectedOption,
    this.location = '',
    this.customLocation = '',
    this.notes = '',
    this.isPersonalConveyanceAllowed = false,
    this.isYardMoveAllowed = false,
    this.isVehicleMoving = false,
    this.isSaving = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  DutyStatus get selectedStatus => selectedOption.toDutyStatus();
  bool get isYardMoves => selectedOption.isYardMoves;

  /// فحص قاعدة إلزامية الملاحظات للقيادة الشخصية وحركة الساحة
  bool get isAnnotationRequired =>
      selectedOption == DutyStatusOption.personalConveyance ||
      selectedOption == DutyStatusOption.yardMoves;

  List<DutyStatusOption> get availableOptions => [
    DutyStatusOption.offDuty,
    DutyStatusOption.sleeperBerth,
    DutyStatusOption.driving,
    DutyStatusOption.onDuty,
    if (isPersonalConveyanceAllowed) DutyStatusOption.personalConveyance,
    if (isYardMoveAllowed) DutyStatusOption.yardMoves,
  ];

  bool get hasValidCustomLocation =>
      customLocation.length >= 5 && customLocation.length <= 60;

  bool get isLocationValid {
    if (customLocation.isNotEmpty) return hasValidCustomLocation;
    final hasGps =
        location.isNotEmpty && location != 'Unknown' && location != 'Location';
    return hasGps;
  }

  bool get isValid =>
      selectedOption != initialOption &&
      isLocationValid &&
      (!isAnnotationRequired || notes.length >= 4) &&
      !(isVehicleMoving && selectedStatus != DutyStatus.driving);

  ChangeStatusState copyWith({
    DutyStatusOption? initialOption,
    DutyStatusOption? selectedOption,
    String? location,
    String? customLocation,
    String? notes,
    bool? isPersonalConveyanceAllowed,
    bool? isYardMoveAllowed,
    bool? isVehicleMoving,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return ChangeStatusState(
      initialOption: initialOption ?? this.initialOption,
      selectedOption: selectedOption ?? this.selectedOption,
      location: location ?? this.location,
      customLocation: customLocation ?? this.customLocation,
      notes: notes ?? this.notes,
      isPersonalConveyanceAllowed:
          isPersonalConveyanceAllowed ?? this.isPersonalConveyanceAllowed,
      isYardMoveAllowed: isYardMoveAllowed ?? this.isYardMoveAllowed,
      isVehicleMoving: isVehicleMoving ?? this.isVehicleMoving,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// متحكم إدارة حالة تغيير واجب السائق
class ChangeStatusNotifier extends StateNotifier<ChangeStatusState> {
  final Ref _ref;

  ChangeStatusNotifier(
    this._ref, {
    required DutyStatus initialStatus,
    required bool isYardMoves,
    required String initialLocation,
    required bool isPersonalConveyanceAllowed,
    required bool isYardMoveAllowed,
    required bool isVehicleMoving,
  }) : super(
         ChangeStatusState(
           initialOption: DutyStatusOption.fromCurrent(
             status: initialStatus,
             isYardMoves: isYardMoves,
           ),
           selectedOption: DutyStatusOption.fromCurrent(
             status: initialStatus,
             isYardMoves: isYardMoves,
           ),
           location: initialLocation,
           isPersonalConveyanceAllowed: isPersonalConveyanceAllowed,
           isYardMoveAllowed: isYardMoveAllowed,
           isVehicleMoving: isVehicleMoving,
         ),
       ) {
    _ref.listen<AsyncValue<DriverRules>>(driverRulesProvider, (_, next) {
      final rules = next.asData?.value;
      if (rules != null) {
        state = state.copyWith(
          isPersonalConveyanceAllowed: rules.isPersonalConveyanceAllowed,
          isYardMoveAllowed: rules.isYardMoveAllowed,
        );
      }
    });

    _ref.listen<bool>(isVehicleMovingProvider, (_, isMoving) {
      state = state.copyWith(isVehicleMoving: isMoving);
    });

    // الموقع الحي (P3): تعبئة تلقائية للعرض، والإحداثيات الحقيقية تُرسل
    // أيضاً مع الحدث نفسه في [submit] — لا موقع فارغ بلا سبب.
    _ref.listen<TrackingState>(trackingStateProvider, (_, next) {
      final text = gpsLocationText(next.currentLocation);
      if (text.isEmpty || text == state.location) return;
      state = state.copyWith(location: text);
    });
  }

  void selectOption(DutyStatusOption option) {
    state = state.copyWith(selectedOption: option, clearError: true);
  }

  void updateNotes(String notes) {
    if (state.notes == notes) return;
    state = state.copyWith(notes: notes, clearError: true);
  }

  void updateCustomLocation(String customLocation) {
    if (state.customLocation == customLocation) return;
    state = state.copyWith(customLocation: customLocation, clearError: true);
  }

  void updateLocation(String location) {
    if (state.location == location) return;
    state = state.copyWith(location: location, clearError: true);
  }

  /// إرسال التغيير مع التحقق المنطقي وتحديث اللوحة تفاعلياً
  Future<DutyChangeResult> submit() async {
    if (state.isSaving) {
      return const DutyChangeAlreadyInProgress();
    }

    if (state.isVehicleMoving && state.selectedStatus != DutyStatus.driving) {
      return const DutyChangeVehicleMoving();
    }

    if (state.selectedOption == DutyStatusOption.personalConveyance &&
        !state.isPersonalConveyanceAllowed) {
      return const DutyChangeEngineRefusal(
        'Personal Conveyance is not permitted',
      );
    }

    if (state.selectedOption == DutyStatusOption.yardMoves &&
        !state.isYardMoveAllowed) {
      return const DutyChangeEngineRefusal('Yard Move is not permitted');
    }

    final effectiveNotes = state.notes.trim();
    if (state.isAnnotationRequired && effectiveNotes.isEmpty) {
      return const DutyChangeAnnotationRequired();
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final parts = <String>[];
      if (state.customLocation.trim().isNotEmpty) {
        parts.add(state.customLocation.trim());
      }
      if (effectiveNotes.isNotEmpty) {
        parts.add(effectiveNotes);
      }
      final combinedAnnotation = parts.isNotEmpty ? parts.join(' - ') : null;

      // 1. تحديث محرك HOS الداخلي (عبر الخادم أولاً كما قبل) — مع
      // إحداثيات GPS الحقيقية إن وُجدت لتُختم في الحدث المرسل للخادم.
      final gps = _ref.read(trackingStateProvider).currentLocation;
      final hasGps = gps != null && (gps.latitude != 0 || gps.longitude != 0);
      final outcome = await _ref
          .read(hosStatusProvider.notifier)
          .changeStatus(
            state.selectedStatus,
            annotation: combinedAnnotation,
            isYardMoves: state.isYardMoves,
            latitude: hasGps ? gps.latitude : null,
            longitude: hasGps ? gps.longitude : null,
          );

      final refusal = outcome.refusal;
      if (refusal != null) {
        if (mounted) {
          state = state.copyWith(
            isSaving: false,
            errorMessage: refusal,
            isSuccess: false,
          );
        }
        return DutyChangeEngineRefusal(refusal);
      }

      // 2. تغذية اللوحة من استجابة POST مباشرة عند حملها لقطة — تتحول
      // الدائرة فوراً دون انتظار GET لاحق. مستمع اللوحة يتخطى إعادة
      // الجلب لأن الحالة مطابقة أصلاً؛ وإن اختلفت لأي سبب يبقى الـ
      // refresh الاحتياطي.
      final serverDashboard = outcome.dashboard;
      if (serverDashboard != null) {
        final currentDashboard = _ref.read(statusDashboardProvider).valueOrNull;
        final updatedDashboard = currentDashboard != null
            ? serverDashboard.copyWith(
                driver: serverDashboard.driver.name.isNotEmpty
                    ? serverDashboard.driver
                    : currentDashboard.driver,
                regulatoryConstraints:
                    serverDashboard.regulatoryConstraints.limits.isNotEmpty
                    ? serverDashboard.regulatoryConstraints
                    : currentDashboard.regulatoryConstraints,
              )
            : serverDashboard;
        _ref
            .read(statusDashboardProvider.notifier)
            .applyServerDashboard(updatedDashboard);
      } else {
        // بلا لقطة في استجابة POST (جسم بلا حقول لوحة أو فشل شبكي —
        // العقد يسمح بـnull). لا نخترع أرقاماً إطلاقاً:
        // - متصل: الخادم هو المرجع — تصحيح صامت فوري من GET، بلا
        //   تعليق نجاح المستخدم على الشبكة.
        // - أوفلاين: نبني لوحة حقيقية من المحرك المحلي (المستعاد من
        //   سجل الخدمة) فيتحدّث فوراً كالوضع المتصل.
        final isConnected = _ref.read(networkInfoProvider).isConnected;
        if (isConnected) {
          unawaited(
            _ref.read(statusDashboardProvider.notifier).reconcileWithServer(),
          );
        } else {
          final local = _buildLocalDashboard();
          if (local != null) {
            _ref
                .read(statusDashboardProvider.notifier)
                .applyServerDashboard(local);
          }
        }
      }

      if (mounted) {
        state = state.copyWith(isSaving: false, isSuccess: true);
      }
      return const DutyChangeSuccess();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
          isSuccess: false,
        );
      }
      return DutyChangeEngineRefusal(e.toString());
    }
  }

  /// لوحة مبنية من المحرك المحلي — تُستخدم عند غياب الخادم (أوفلاين فقط؛
  /// مع الاتصال يبقى الخادم هو المرجع).
  StatusDashboard? _buildLocalDashboard() {
    final engine = _ref.read(hosEngineProvider);
    final result = engine.currentStatus;
    if (result is! HosEngineReady) return null;
    final current = _ref.read(statusDashboardProvider).valueOrNull;
    final driverId = _ref.read(currentDriverIdProvider);
    return const HosOfflineDashboardBuilder()
        .build(
          engineResult: result,
          driverId: const DriverId(0),
          driverName: '',
          driverDisplayText: '',
        )
        .copyWith(
          driver:
              current?.driver ??
              DriverRef(id: DriverId(driverId ?? 0), name: '', displayText: ''),
        );
  }
}

/// مزود حالة تغيير الخدمة (Change Status Provider)
final changeStatusProvider =
    StateNotifierProvider.autoDispose<ChangeStatusNotifier, ChangeStatusState>((
      ref,
    ) {
      final dashboard = ref.watch(statusDashboardProvider).valueOrNull;
      final currentCode = dashboard?.currentDutyStatus;

      final engineState = ref.read(hosStatusProvider);
      final currentHosStatus = (engineState is HosEngineReady)
          ? engineState.update.currentStatus
          : DutyStatus.offDuty;

      final initialOption = currentCode != null
          ? DutyStatusOption.fromStatusCode(currentCode)
          : DutyStatusOption.fromCurrent(
              status: currentHosStatus,
              isYardMoves: false,
            );

      final rules = ref.read(driverRulesProvider).asData?.value;
      final isPersonalConveyanceAllowed =
          rules?.isPersonalConveyanceAllowed ?? false;
      final isYardMoveAllowed = rules?.isYardMoveAllowed ?? false;
      final isMoving = ref.read(isVehicleMovingProvider);

      return ChangeStatusNotifier(
        ref,
        initialStatus: initialOption.toDutyStatus(),
        isYardMoves: initialOption.isYardMoves,
        // P3: تعبئة الموقع من GPS الحقيقي بدل '' — كان زر UPDATE يبقى
        // معطلاً حتى مع قفل موقع حي على الجهاز.
        initialLocation: gpsLocationText(
          ref.read(trackingStateProvider).currentLocation,
        ),
        isPersonalConveyanceAllowed: isPersonalConveyanceAllowed,
        isYardMoveAllowed: isYardMoveAllowed,
        isVehicleMoving: isMoving,
      );
    });

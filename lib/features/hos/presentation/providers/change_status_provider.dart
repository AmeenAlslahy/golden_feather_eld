import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/entities/hos_models.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../core/providers/driver_rules_provider.dart';
import '../../domain/engine/hos_rules_engine.dart';
import 'hos_engine_provider.dart';
import 'hos_provider.dart';
import 'status_dashboard_providers.dart';

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

  ChangeStatusState copyWith({
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
  }) : super(ChangeStatusState(
          selectedOption: DutyStatusOption.fromCurrent(
            status: initialStatus,
            isYardMoves: isYardMoves,
          ),
          location: initialLocation,
          isPersonalConveyanceAllowed: isPersonalConveyanceAllowed,
          isYardMoveAllowed: isYardMoveAllowed,
          isVehicleMoving: isVehicleMoving,
        )) {
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
  }

  void selectOption(DutyStatusOption option) {
    state = state.copyWith(
      selectedOption: option,
      clearError: true,
    );
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
      return const DutyChangeEngineRefusal('Personal Conveyance is not permitted');
    }

    if (state.selectedOption == DutyStatusOption.yardMoves &&
        !state.isYardMoveAllowed) {
      return const DutyChangeEngineRefusal('Yard Move is not permitted');
    }

    final effectiveNotes = state.notes.trim();
    if (state.isAnnotationRequired && effectiveNotes.isEmpty) {
      return const DutyChangeAnnotationRequired();
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      final parts = <String>[];
      if (state.customLocation.trim().isNotEmpty) {
        parts.add(state.customLocation.trim());
      }
      if (effectiveNotes.isNotEmpty) {
        parts.add(effectiveNotes);
      }
      final combinedAnnotation = parts.isNotEmpty ? parts.join(' - ') : null;

      // 1. تحديث محرك HOS الداخلي
      final error = await _ref.read(hosStatusProvider.notifier).changeStatus(
            state.selectedStatus,
            annotation: combinedAnnotation,
            isYardMoves: state.isYardMoves,
          );

      if (error != null) {
        if (mounted) {
          state = state.copyWith(
            isSaving: false,
            errorMessage: error,
            isSuccess: false,
          );
        }
        return DutyChangeEngineRefusal(error);
      }

      // لا حاجة لاستدعاء statusDashboardProvider.notifier.changeStatus هنا
      // لأن statusDashboardProvider يستمع بالفعل لـ hosStatusProvider 
      // ويقوم بتحديث نفسه (refresh) تلقائياً عند تغيير الحالة في المحرك.

      if (mounted) {
        state = state.copyWith(
          isSaving: false,
          isSuccess: true,
        );
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
}

/// مزود حالة تغيير الخدمة (Change Status Provider)
final changeStatusProvider =
    StateNotifierProvider.autoDispose<ChangeStatusNotifier, ChangeStatusState>(
  (ref) {
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
      initialLocation: '',
      isPersonalConveyanceAllowed: isPersonalConveyanceAllowed,
      isYardMoveAllowed: isYardMoveAllowed,
      isVehicleMoving: isMoving,
    );
  },
);

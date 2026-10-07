import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/entities/hos_models.dart';
import '../../../account/application/models/rules_screen_model.dart'; // ignore_architecture: driver rules configuration accessed by HOS change status
import '../../../account/presentation/providers/rules_screen_provider.dart'; // ignore_architecture: driver rules configuration accessed by HOS change status
import '../../domain/engine/hos_rules_engine.dart';
import 'hos_engine_provider.dart';
import 'hos_provider.dart';
import 'status_dashboard_providers.dart';

/// تمثيل نمطي صريح لنتائج تغيير واجب السائق دون سلاسل نصية سحرية
sealed class DutyChangeResult {
  const DutyChangeResult();
}

class DutyChangeSuccess extends DutyChangeResult {
  const DutyChangeSuccess();
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
  final DutyStatus selectedStatus;
  final bool isYardMoves;
  final String location;
  final String notes;
  final bool isPersonalConveyanceAllowed;
  final bool isYardMoveAllowed;
  final bool isVehicleMoving;
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  const ChangeStatusState({
    required this.selectedStatus,
    this.isYardMoves = false,
    this.location = '',
    this.notes = '',
    this.isPersonalConveyanceAllowed = false,
    this.isYardMoveAllowed = false,
    this.isVehicleMoving = false,
    this.isSaving = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  /// فحص قاعدة إلزامية الملاحظات للقيادة الشخصية وحركة الساحة
  bool get isAnnotationRequired =>
      selectedStatus == DutyStatus.personalUse ||
      (selectedStatus == DutyStatus.onDutyNotDriving && isYardMoves);

  ChangeStatusState copyWith({
    DutyStatus? selectedStatus,
    bool? isYardMoves,
    String? location,
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
      selectedStatus: selectedStatus ?? this.selectedStatus,
      isYardMoves: isYardMoves ?? this.isYardMoves,
      location: location ?? this.location,
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
    required bool isPersonalConveyanceAllowed,
    required bool isYardMoveAllowed,
    required bool isVehicleMoving,
  }) : super(ChangeStatusState(
          selectedStatus: initialStatus,
          isPersonalConveyanceAllowed: isPersonalConveyanceAllowed,
          isYardMoveAllowed: isYardMoveAllowed,
          isVehicleMoving: isVehicleMoving,
        )) {
    _ref.listen<AsyncValue<RulesScreenModel>>(rulesScreenProvider, (_, next) {
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

  void selectStatus(DutyStatus status) {
    if (status == DutyStatus.driving) return;
    state = state.copyWith(
      selectedStatus: status,
      isYardMoves: status != DutyStatus.onDutyNotDriving ? false : state.isYardMoves,
      clearError: true,
    );
  }

  void toggleYardMoves() {
    final next = !state.isYardMoves;
    state = state.copyWith(
      isYardMoves: next,
      selectedStatus: next ? DutyStatus.onDutyNotDriving : state.selectedStatus,
      clearError: true,
    );
  }

  void updateNotes(String notes) {
    if (state.notes == notes) return;
    state = state.copyWith(notes: notes, clearError: true);
  }

  void updateLocation(String location) {
    if (state.location == location) return;
    state = state.copyWith(location: location, clearError: true);
  }

  /// إرسال التغيير مع التحقق المنطقي وتحديث اللوحة تفاعلياً
  Future<DutyChangeResult> submit() async {
    if (state.isSaving) {
      return const DutyChangeSuccess();
    }

    if (state.isVehicleMoving) {
      return const DutyChangeVehicleMoving();
    }

    final effectiveNotes = state.notes.trim();
    if (state.isAnnotationRequired && effectiveNotes.isEmpty) {
      return const DutyChangeAnnotationRequired();
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    final error = await _ref.read(hosStatusProvider.notifier).changeStatus(
          state.selectedStatus,
          annotation: effectiveNotes.isNotEmpty ? effectiveNotes : null,
          isYardMoves: state.isYardMoves,
        );

    if (!mounted) {
      return error != null
          ? DutyChangeEngineRefusal(error)
          : const DutyChangeSuccess();
    }

    state = state.copyWith(
      isSaving: false,
      errorMessage: error,
      isSuccess: error == null,
    );

    if (error == null) {
      // مزامنة تفاعلية: تحديث اللوحة تلقائياً
      _ref.read(statusDashboardProvider.notifier).refresh();
      return const DutyChangeSuccess();
    }

    return DutyChangeEngineRefusal(error);
  }
}

/// مزود حالة تغيير الخدمة (Change Status Provider)
final changeStatusProvider =
    StateNotifierProvider.autoDispose<ChangeStatusNotifier, ChangeStatusState>(
  (ref) {
    final engineState = ref.read(hosStatusProvider);
    final initialStatus = (engineState is HosEngineReady)
        ? engineState.update.currentStatus
        : DutyStatus.offDuty;

    final rules = ref.read(rulesScreenProvider).asData?.value;
    final isPersonalConveyanceAllowed =
        rules?.isPersonalConveyanceAllowed ?? false;
    final isYardMoveAllowed = rules?.isYardMoveAllowed ?? false;
    final isMoving = ref.read(isVehicleMovingProvider);

    return ChangeStatusNotifier(
      ref,
      initialStatus: initialStatus,
      isPersonalConveyanceAllowed: isPersonalConveyanceAllowed,
      isYardMoveAllowed: isYardMoveAllowed,
      isVehicleMoving: isMoving,
    );
  },
);

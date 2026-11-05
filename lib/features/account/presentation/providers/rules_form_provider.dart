import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../application/models/rules_screen_model.dart';
import '../../application/models/rules_screen_update_request.dart';
import '../../data/providers/rules_screen_providers.dart';
import 'rules_screen_provider.dart';

sealed class SaveRulesOutcome {
  const SaveRulesOutcome();
}

class SaveRulesSuccess extends SaveRulesOutcome {
  final RulesScreenModel model;
  const SaveRulesSuccess(this.model);
}

class SaveRulesSessionExpired extends SaveRulesOutcome {
  const SaveRulesSessionExpired();
}

class SaveRulesSixteenHourIneligible extends SaveRulesOutcome {
  const SaveRulesSixteenHourIneligible();
}

class SaveRulesError extends SaveRulesOutcome {
  final Object error;
  const SaveRulesError(this.error);
}

class RulesFormState {
  final String? cycleRule;
  final String? cargoType;
  final String? restart;
  final String? restBreak;
  final bool? sixteenHourException;
  final bool isSaving;
  final SaveRulesOutcome? lastOutcome;

  const RulesFormState({
    this.cycleRule,
    this.cargoType,
    this.restart,
    this.restBreak,
    this.sixteenHourException,
    this.isSaving = false,
    this.lastOutcome,
  });

  /// The SAVE action is only enabled when the 16-Hour Short-Haul Exception
  /// is explicitly active and no save operation is in flight.
  bool get canSave => !isSaving && (sixteenHourException == true);

  RulesFormState copyWith({
    String? cycleRule,
    String? cargoType,
    String? restart,
    String? restBreak,
    bool? sixteenHourException,
    bool? isSaving,
    SaveRulesOutcome? Function()? lastOutcome,
  }) {
    return RulesFormState(
      cycleRule: cycleRule ?? this.cycleRule,
      cargoType: cargoType ?? this.cargoType,
      restart: restart ?? this.restart,
      restBreak: restBreak ?? this.restBreak,
      sixteenHourException: sixteenHourException ?? this.sixteenHourException,
      isSaving: isSaving ?? this.isSaving,
      lastOutcome: lastOutcome != null ? lastOutcome() : this.lastOutcome,
    );
  }
}

/// حقول النموذج التي عدّلها المستخدم — تُهيأ تلقائياً من مزود شاشة القواعد.
class RulesFormNotifier extends AutoDisposeNotifier<RulesFormState> {
  RulesScreenModel? _sourceModel;

  @override
  RulesFormState build() {
    final rulesAsync = ref.watch(rulesScreenProvider);
    final model = rulesAsync.valueOrNull;
    if (model == null) {
      return const RulesFormState();
    }
    _sourceModel = model;
    return RulesFormState(
      cycleRule: model.cycleRule,
      cargoType: model.cargoType,
      restart: model.restart,
      restBreak: model.restBreak,
      sixteenHourException: model.sixteenHourException,
      isSaving: false,
    );
  }

  void syncFromModel(RulesScreenModel model) {
    if (identical(_sourceModel, model)) return;
    _sourceModel = model;
    state = RulesFormState(
      cycleRule: model.cycleRule,
      cargoType: model.cargoType,
      restart: model.restart,
      restBreak: model.restBreak,
      sixteenHourException: model.sixteenHourException,
      isSaving: state.isSaving,
    );
  }

  void updateRuleField(String fieldName, String value) {
    switch (fieldName) {
      case 'cycleRule':
        state = state.copyWith(cycleRule: value);
        break;
      case 'cargoType':
        state = state.copyWith(cargoType: value);
        break;
      case 'restart':
        state = state.copyWith(restart: value);
        break;
      case 'restBreak':
        state = state.copyWith(restBreak: value);
        break;
      default:
        AppLogger.warning(
          'RulesFormNotifier.updateRuleField: unrecognized fieldName "$fieldName"',
        );
        break;
    }
  }

  void setSixteenHourException(bool value) {
    state = state.copyWith(sixteenHourException: value);
  }

  void setSaving(bool value) {
    state = state.copyWith(isSaving: value);
  }

  void clearOutcome() {
    state = state.copyWith(lastOutcome: () => null);
  }

  Future<SaveRulesOutcome> saveRules([RulesScreenModel? modelParam]) async {
    final user = ref.read(authStateProvider).user;
    final parsedDriverId = user == null ? null : int.tryParse(user.id);
    if (parsedDriverId == null) {
      const outcome = SaveRulesSessionExpired();
      state = state.copyWith(lastOutcome: () => outcome);
      return outcome;
    }

    final model =
        modelParam ?? _sourceModel ?? ref.read(rulesScreenProvider).valueOrNull;
    if (model == null) {
      const outcome = SaveRulesError('No rules data loaded');
      state = state.copyWith(lastOutcome: () => outcome);
      return outcome;
    }

    state = state.copyWith(isSaving: true, lastOutcome: () => null);
    SaveRulesOutcome outcome = const SaveRulesError('Unknown save error');
    try {
      final sixteenEligible =
          model.editableFields.contains('sixteenHourException') ||
              model.editableFields.contains('shortHaul16HourException');
      final sixteenValue =
          state.sixteenHourException ?? model.sixteenHourException;
      if (state.sixteenHourException != null &&
          sixteenValue &&
          !sixteenEligible) {
        outcome = const SaveRulesSixteenHourIneligible();
        return outcome;
      }

      final request = RulesScreenUpdateRequest(
        cycleRule: state.cycleRule ?? model.cycleRule,
        cargoType: state.cargoType ?? model.cargoType,
        restart: state.restart ?? model.restart,
        restBreak: state.restBreak ?? model.restBreak,
        sixteenHourException: sixteenEligible
            ? sixteenValue
            : model.sixteenHourException,
        personalConveyanceAllowed: model.isPersonalConveyanceAllowed,
        yardMovesAllowed: model.isYardMoveAllowed,
      );

      final result = await ref
          .read(updateRulesUseCaseProvider)
          .execute(driverId: DriverId(parsedDriverId), request: request);

      outcome = result.fold<SaveRulesOutcome>(
        (failure) => SaveRulesError(failure),
        (updatedModel) {
          ref.invalidate(rulesScreenProvider);
          return SaveRulesSuccess(updatedModel);
        },
      );
    } catch (e) {
      outcome = SaveRulesError(e);
    } finally {
      state = state.copyWith(isSaving: false, lastOutcome: () => outcome);
    }
    return outcome;
  }
}

final rulesFormProvider =
    AutoDisposeNotifierProvider<RulesFormNotifier, RulesFormState>(
      RulesFormNotifier.new,
    );

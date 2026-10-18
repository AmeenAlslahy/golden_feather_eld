import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/models/rules_screen_model.dart';

class RulesFormState {
  final String? cycleRule;
  final String? cargoType;
  final String? restart;
  final String? restBreak;
  final bool? sixteenHourException;
  final bool isSaving;

  const RulesFormState({
    this.cycleRule,
    this.cargoType,
    this.restart,
    this.restBreak,
    this.sixteenHourException,
    this.isSaving = false,
  });

  RulesFormState copyWith({
    String? cycleRule,
    String? cargoType,
    String? restart,
    String? restBreak,
    bool? sixteenHourException,
    bool? isSaving,
  }) {
    return RulesFormState(
      cycleRule: cycleRule ?? this.cycleRule,
      cargoType: cargoType ?? this.cargoType,
      restart: restart ?? this.restart,
      restBreak: restBreak ?? this.restBreak,
      sixteenHourException: sixteenHourException ?? this.sixteenHourException,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// حقول النموذج التي عدّلها المستخدم فقط — القيم الغائبة تُقرأ من نموذج الخادم.
class RulesFormNotifier extends AutoDisposeNotifier<RulesFormState> {
  RulesScreenModel? _sourceModel;

  @override
  RulesFormState build() => const RulesFormState();

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
    }
  }

  void setSixteenHourException(bool value) {
    state = state.copyWith(sixteenHourException: value);
  }

  void setSaving(bool value) {
    state = state.copyWith(isSaving: value);
  }
}

final rulesFormProvider =
    AutoDisposeNotifierProvider<RulesFormNotifier, RulesFormState>(
  RulesFormNotifier.new,
);

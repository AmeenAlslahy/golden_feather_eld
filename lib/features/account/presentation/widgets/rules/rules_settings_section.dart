import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/eld_info_row.dart';
import '../../../application/models/rules_screen_model.dart';
import '../../providers/rules_form_provider.dart';
import '../../utils/account_display.dart';
import 'rule_dropdown_field.dart';
import 'rule_switch_row.dart';

class RulesSettingsSection extends ConsumerWidget {
  final RulesScreenModel model;
  final bool dense;

  const RulesSettingsSection({
    super.key,
    required this.model,
    this.dense = true,
  });

  List<String> _optionsFor(String field) {
    return List<String>.from(model.options[field] ?? const <String>[]);
  }

  Widget _buildRuleItem({
    required String fieldName,
    required String label,
    required String serverValue,
    required String? formValue,
    required List<String> options,
    required Set<String> editable,
    required ValueChanged<String> onChanged,
  }) {
    if (editable.contains(fieldName) && options.isNotEmpty) {
      return RuleDropdownField(
        label: label,
        value: formValue ?? serverValue,
        options: options,
        dense: dense,
        onChanged: onChanged,
      );
    }
    return EldInfoRow(label: label, value: serverValue, dense: dense);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final form = ref.watch(rulesFormProvider);
    final notifier = ref.read(rulesFormProvider.notifier);
    final editable = model.editableFields;
    final sixteenValue =
        form.sixteenHourException ?? model.sixteenHourException;

    return Column(
      children: [
        if (model.ruleSource.trim().isNotEmpty) ...[
          EldInfoRow(
            label: loc.ruleSource,
            value: model.ruleSource,
            dense: dense,
          ),
          Divider(color: context.border, height: AppSpacing.dividerHeight),
        ],
        _buildRuleItem(
          fieldName: 'cycleRule',
          label: loc.cycleRule,
          serverValue: model.cycleRule,
          formValue: form.cycleRule,
          options: _optionsFor('cycleRule'),
          editable: editable,
          onChanged: (val) => notifier.updateRuleField('cycleRule', val),
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        _buildRuleItem(
          fieldName: 'cargoType',
          label: loc.cargoType,
          serverValue: model.cargoType,
          formValue: form.cargoType,
          options: _optionsFor('cargoType'),
          editable: editable,
          onChanged: (val) => notifier.updateRuleField('cargoType', val),
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        _buildRuleItem(
          fieldName: 'restart',
          label: loc.restartRule,
          serverValue: model.restart,
          formValue: form.restart,
          options: _optionsFor('restart'),
          editable: editable,
          onChanged: (val) => notifier.updateRuleField('restart', val),
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        _buildRuleItem(
          fieldName: 'restBreak',
          label: loc.restBreakRule,
          serverValue: model.restBreak,
          formValue: form.restBreak,
          options: _optionsFor('restBreak'),
          editable: editable,
          onChanged: (val) => notifier.updateRuleField('restBreak', val),
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        if (editable.contains('sixteenHourException'))
          RuleSwitchRow(
            label: loc.sixteenHourException,
            value: sixteenValue,
            dense: dense,
            onChanged: (val) => notifier.setSixteenHourException(val),
          )
        else
          EldInfoRow(
            label: loc.sixteenHourException,
            value: model.sixteenHourException ? loc.yes : loc.no,
            dense: dense,
          ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.personalConveyance,
          value: serverSettingText(loc, model, const [
            'personalConveyance',
            'personalConveyanceEnabled',
          ]),
          dense: dense,
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.yardMoves,
          value: serverSettingText(loc, model, const [
            'yardMoves',
            'yardMoveEnabled',
          ]),
          dense: dense,
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.unlimitedTrailers,
          value: serverSettingText(loc, model, const [
            'unlimitedTrailers',
            'unlimitedTrailerEnabled',
          ]),
          dense: dense,
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.unlimitedShippingDocs,
          value: serverSettingText(loc, model, const [
            'unlimitedShippingDocuments',
            'unlimitedShippingEnabled',
          ]),
          dense: dense,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/rules_screen_model.dart';
import '../../domain/usecases/update_rules_use_case.dart';
import '../providers/rules_screen_provider.dart';

class RulesPage extends ConsumerStatefulWidget {
  const RulesPage({super.key});

  @override
  ConsumerState<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<RulesPage> {
  // Form State
  String? _cycleRule;
  String? _cargoType;
  String? _restart;
  String? _restBreak;
  bool? _sixteenHourException;
  bool _isSaving = false;

  bool get _isFormValid {
    return _cycleRule != null && _cycleRule!.isNotEmpty &&
           _cargoType != null && _cargoType!.isNotEmpty &&
           _restart != null && _restart!.isNotEmpty &&
           _restBreak != null && _restBreak!.isNotEmpty;
  }

  void _initForm(RulesScreenModel model) {
    _cycleRule ??= model.cycleRule;
    _cargoType ??= model.cargoType;
    _restart ??= model.restart;
    _restBreak ??= model.restBreak;
    _sixteenHourException ??= model.sixteenHourException;
  }

  Future<void> _saveRules(RulesScreenModel model) async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.formIsIncompletePleaseFill),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final useCase = ref.read(updateRulesUseCaseProvider);
      final request = RulesScreenUpdateRequest(
        cycleRule: _cycleRule!,
        cargoType: _cargoType!,
        restart: _restart!,
        restBreak: _restBreak!,
        sixteenHourException: _sixteenHourException!,
      );

      final result = await useCase.execute(request);
      if (mounted) {
        result.fold(
          (failure) {
            final serverMsg = failure.context?['serverMessage'] as String?;
            final displayMsg = serverMsg ?? (context.loc.failedToUpdateRulesFailure);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(displayMsg), backgroundColor: AppColors.dangerRed),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rules updated successfully'), backgroundColor: AppColors.successGreen),
            );
            ref.invalidate(rulesScreenProvider);
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildFlatRow(BuildContext context, String fieldName, String label, String value, List<String> options, Set<String> editable) {
    if (editable.contains(fieldName) && options.isNotEmpty) {
      String currentValue = value;
      switch (fieldName) {
        case 'cycleRule':
          currentValue = _cycleRule!;
          break;
        case 'cargoType':
          currentValue = _cargoType!;
          break;
        case 'restart':
          currentValue = _restart!;
          break;
        case 'restBreak':
          currentValue = _restBreak!;
          break;
      }

      if (!options.contains(currentValue) && options.isNotEmpty) {
        currentValue = options.first;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
            Expanded(
              flex: 3,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentValue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: options.map((String opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt, style: Theme.of(context).textTheme.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        switch (fieldName) {
                          case 'cycleRule':
                            _cycleRule = newValue;
                            break;
                          case 'cargoType':
                            _cargoType = newValue;
                            break;
                          case 'restart':
                            _restart = newValue;
                            break;
                          case 'restBreak':
                            _restBreak = newValue;
                            break;
                        }
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildInfoRow(context, label, value);
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          AppGap.md,
          Flexible(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  String _getAllowedText(BuildContext context, dynamic value) {
    final isAllowed = value == true || value == 'Allowed';
    if (Localizations.localeOf(context).languageCode == 'ar') {
      return isAllowed ? 'مسموح' : 'ممنوع';
    }
    return isAllowed ? 'Allowed' : 'Forbidden';
  }

  @override
  Widget build(BuildContext context) {
    final rulesScreenAsync = ref.watch(rulesScreenProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          context.loc.rules,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: rulesScreenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (model) {
          _initForm(model);
          final editable = model.editableFields;
          final hasEditableFields = editable.any((field) {
            if (field == 'sixteenHourException') return true;
            return (model.options[field] ?? []).isNotEmpty;
          });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (model.notice.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.dialog),
                      border: Border.all(
                        color: AppColors.warningYellow.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.textPrimary),
                        AppGap.hSm,
                        Expanded(
                          child: Text(
                            model.notice,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Container(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      _buildFlatRow(context, 'cycleRule', context.loc.cycleLimitTitle, model.cycleRule, model.options['cycleRule'] ?? [], editable),
                      const Divider(height: 1),
                      _buildFlatRow(context, 'cargoType', context.loc.cargoType, model.cargoType, model.options['cargoType'] ?? [], editable),
                      const Divider(height: 1),
                      _buildFlatRow(context, 'restart', context.loc.restart, model.restart, model.options['restart'] ?? [], editable),
                      const Divider(height: 1),
                      _buildFlatRow(context, 'restBreak', context.loc.restBreak, model.restBreak, model.options['restBreak'] ?? [], editable),
                      const Divider(height: 1),
                      
                      if (editable.contains('sixteenHourException'))
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            title: Text('16-Hour Short-Haul\nException', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            value: _sixteenHourException ?? false,
                            onChanged: (val) {
                              setState(() => _sixteenHourException = val);
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('16-Hour Short-Haul\nException', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              Switch(value: model.sixteenHourException, onChanged: null),
                            ],
                          ),
                        ),
                      const Divider(height: 1),

                      _buildInfoRow(context, 'Personal Conveyance', _getAllowedText(context, model.fixedSettings['personalConveyance'])),
                      const Divider(height: 1),
                      _buildInfoRow(context, 'Yard Moves', _getAllowedText(context, model.fixedSettings['yardMoves'])),
                      const Divider(height: 1),
                      _buildInfoRow(context, 'Unlimited Trailers', _getAllowedText(context, model.fixedSettings['unlimitedTrailers'])),
                      const Divider(height: 1),
                      _buildInfoRow(context, 'Unlimited Shipping\nDocuments', _getAllowedText(context, model.fixedSettings['unlimitedShippingDocuments'])),
                      const Divider(height: 1),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isSaving || !hasEditableFields || !_isFormValid) ? null : () => _saveRules(model),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen.shade300,
                            disabledBackgroundColor: Colors.lightGreen.shade300.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isSaving 
                              ? const SizedBox(height: AppSpacing.loaderSize, width: AppSpacing.loaderSize, child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2))
                              : const Text('SAVE', style: TextStyle(color: AppColors.surface, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      AppGap.xl,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info, color: Colors.grey, size: 20),
                          AppGap.hSm,
                          Flexible(
                            child: Text(
                              'Please contact your fleet manager to change rules\nor to add exceptions.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
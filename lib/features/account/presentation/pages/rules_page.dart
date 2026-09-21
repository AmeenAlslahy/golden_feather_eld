import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/rules_screen_provider.dart';
import '../../application/usecases/update_rules_use_case.dart';
import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';
import '../../application/models/rules_screen_model.dart';

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'البيانات غير مكتملة، يرجى ملء جميع الحقول أولاً.' : 'Form is incomplete, please fill all fields.'),
          backgroundColor: Colors.red,
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
            final displayMsg = serverMsg ?? (isArabic ? 'فشل تحديث القواعد: ${failure.l10nKey}' : 'Failed to update rules: ${failure.l10nKey}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(displayMsg), backgroundColor: Colors.red),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rules updated successfully'), backgroundColor: Colors.green),
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

  Widget _buildDropdownOrInfo(String fieldName, String label, String value, List<String> options, Set<String> editable) {
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

      // Ensure current value is in options to prevent DropdownMenuItem errors
      if (!options.contains(currentValue) && options.isNotEmpty) {
        currentValue = options.first;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: options.map((String opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
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
      );
    } else {
      return EldInfoRow(label: label, value: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesScreenAsync = ref.watch(rulesScreenProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = context.loc;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.rules,
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
          final config = model.limits;
          final editable = model.editableFields;
          final hasEditableFields = editable.any((field) {
            if (field == 'sixteenHourException') return true;
            return (model.options[field] ?? []).isNotEmpty;
          });

          String hours(int minutes) {
            final h = minutes ~/ 60;
            final m = minutes % 60;
            if (m == 0) return isArabic ? '$h ساعة' : '$h h';
            return isArabic ? '$h س $m د' : '${h}h ${m}m';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (model.notice.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warningYellow.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.textPrimary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            model.notice,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),

                EldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'الدورة المطبقة' : 'Active Cycle',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EldInfoRow(
                        label: isArabic ? 'مصدر القاعدة' : 'Rule Source',
                        value: model.ruleSource,
                      ),
                      _buildDropdownOrInfo('cycleRule', isArabic ? 'الدورة' : 'Cycle', model.cycleRule, model.options['cycleRule'] ?? [], editable),
                      _buildDropdownOrInfo('restart', isArabic ? 'إعادة التشغيل' : 'Restart', model.restart, model.options['restart'] ?? [], editable),
                      _buildDropdownOrInfo('cargoType', isArabic ? 'نوع الحمولة' : 'Cargo Type', model.cargoType, model.options['cargoType'] ?? [], editable),
                      _buildDropdownOrInfo('restBreak', isArabic ? 'استراحة إلزامية' : 'Rest Break', model.restBreak, model.options['restBreak'] ?? [], editable),
                      
                      if (editable.contains('sixteenHourException'))
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            title: const Text('16-Hour Exception'),
                            value: _sixteenHourException ?? false,
                            onChanged: (val) {
                              setState(() => _sixteenHourException = val);
                            },
                          ),
                        )
                      else
                        EldInfoRow(
                          label: '16-Hour Exception',
                          value: model.sixteenHourException ? 'Yes' : 'No',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (hasEditableFields)
                  ElevatedButton(
                    onPressed: (_isSaving || !_isFormValid) ? null : () => _saveRules(model),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isArabic ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white)),
                  ),
                  
                const SizedBox(height: AppSpacing.md),

                EldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'الحدود اليومية' : 'Daily Limits',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      EldInfoRow(
                        label: isArabic ? 'القيادة' : 'Driving',
                        value: hours(config.drivingLimitMinutes),
                      ),
                      EldInfoRow(
                        label: isArabic ? 'نافذة العمل' : 'Shift window',
                        value: hours(config.shiftLimitMinutes),
                      ),
                      EldInfoRow(
                        label: isArabic ? 'استراحة إلزامية' : 'Required break',
                        value: '${config.breakDurationMinutes} ${isArabic ? 'د' : 'min'} / ${hours(config.driveBeforeBreakMinutes)}',
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

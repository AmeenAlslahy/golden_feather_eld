import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../application/models/rules_screen_model.dart';
import '../../application/usecases/update_rules_use_case.dart';
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

  /// النموذج الذي مُلئت منه الحقول. `FutureProvider` يعيد نفس الكائن حتى
  /// يُبطل (بعد الحفظ) — عند وصول نموذج جديد يجب إعادة الملء وإلا بقيت
  /// القيم القديمة ظاهرة رغم تحديث الخادم.
  RulesScreenModel? _initializedModel;

  bool get _isFormValid {
    return _cycleRule != null && _cycleRule!.isNotEmpty &&
           _cargoType != null && _cargoType!.isNotEmpty &&
           _restart != null && _restart!.isNotEmpty &&
           _restBreak != null && _restBreak!.isNotEmpty;
  }

  void _initForm(RulesScreenModel model) {
    if (identical(_initializedModel, model)) return;
    _initializedModel = model;
    _cycleRule = model.cycleRule;
    _cargoType = model.cargoType;
    _restart = model.restart;
    _restBreak = model.restBreak;
    _sixteenHourException = model.sixteenHourException;
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
      final sixteenEligible =
          model.editableFields.contains('sixteenHourException');
      if ((_sixteenHourException ?? false) && !sixteenEligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'لا يمكن تفعيل استثناء 16 ساعة إلا إذا تحققت شروطه.'
                : 'The 16-hour exception cannot be enabled unless its conditions are met.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final request = RulesScreenUpdateRequest(
        cycleRule: _cycleRule!,
        cargoType: _cargoType!,
        restart: _restart!,
        restBreak: _restBreak!,
        sixteenHourException:
            sixteenEligible ? _sixteenHourException! : model.sixteenHourException,
      );

      final result = await useCase.execute(request);
      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appErrorUserMessage(failure, isArabic: isArabic)),
                backgroundColor: Colors.red,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic ? 'تم تحديث القواعد.' : 'Rules updated successfully',
                ),
                backgroundColor: Colors.green,
              ),
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

  String _serverSetting(Map<String, dynamic> settings, List<String> keys) {
    for (final key in keys) {
      final value = settings[key];
      if (value == null) continue;
      if (value is bool) return value ? 'Allowed' : 'Forbidden';
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return 'Not provided by the server';
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
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: options.map((String opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt, overflow: TextOverflow.ellipsis),
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
        title: Text(
          loc.rules,
          style: context.styles.appBarTitle,
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
        error: (err, stack) => EldRetryView(
          message: anyErrorUserMessage(err, isArabic: isArabic),
          onRetry: () => ref.invalidate(rulesScreenProvider),
        ),
        data: (model) {
          _initForm(model);
          final config = model.limits;
          List<String> optionsFor(String field) {
            return List<String>.from(model.options[field] ?? const <String>[]);
          }
          final editable = model.editableFields;

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

                Column(
                  children: [
                    if (model.ruleSource.trim().isNotEmpty)
                      _buildDropdownOrInfo('ruleSource', isArabic ? 'مصدر القاعدة' : 'Rule Source', model.ruleSource, const [], editable),
                    _buildDropdownOrInfo('cycleRule', isArabic ? 'قاعدة الدورة' : 'Cycle Rule', model.cycleRule, optionsFor('cycleRule'), editable),
                    _buildDropdownOrInfo('cargoType', isArabic ? 'نوع الحمولة' : 'Cargo Type', model.cargoType, optionsFor('cargoType'), editable),
                    _buildDropdownOrInfo('restart', isArabic ? 'إعادة التشغيل' : 'Restart', model.restart, optionsFor('restart'), editable),
                    _buildDropdownOrInfo('restBreak', isArabic ? 'الاستراحة' : 'Rest Break', model.restBreak, optionsFor('restBreak'), editable),
                    if (editable.contains('sixteenHourException'))
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(isArabic
                            ? 'استثناء 16 ساعة'
                            : '16-Hour Short-Haul Exception'),
                        value: _sixteenHourException ?? false,
                        onChanged: (val) {
                          setState(() => _sixteenHourException = val);
                        },
                      )
                    else
                      EldInfoRow(
                        label: isArabic
                            ? 'استثناء 16 ساعة'
                            : '16-Hour Short-Haul Exception',
                        value: model.sixteenHourException ? 'Yes' : 'No',
                      ),
                    EldInfoRow(
                      label: 'Personal Conveyance',
                      value: _serverSetting(model.fixedSettings, const [
                        'personalConveyance',
                        'personalConveyanceEnabled',
                      ]),
                    ),
                    EldInfoRow(
                      label: 'Yard Moves',
                      value: _serverSetting(model.fixedSettings, const [
                        'yardMoves',
                        'yardMoveEnabled',
                      ]),
                    ),
                    EldInfoRow(
                      label: 'Unlimited Trailers',
                      value: _serverSetting(model.fixedSettings, const [
                        'unlimitedTrailers',
                        'unlimitedTrailerEnabled',
                      ]),
                    ),
                    EldInfoRow(
                      label: 'Unlimited Shipping Documents',
                      value: _serverSetting(model.fixedSettings, const [
                        'unlimitedShippingDocuments',
                        'unlimitedShippingEnabled',
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                AppButton(
                  label: 'SAVE',
                  type: EldButtonType.send,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : () => _saveRules(model),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isArabic
                      ? 'يرجى الاتصال بمدير الأسطول لتغيير القواعد أو إضافة استثناءات.'
                      : 'Please contact your fleet manager to change rules or to add exceptions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                        label: isArabic ? 'دورة العمل' : 'Cycle',
                        value: '${config.cycleLimitHours} / ${config.maxConsecutiveDays}',
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

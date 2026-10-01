import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/rules_screen_provider.dart';
import '../../application/usecases/update_rules_use_case.dart';
import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';
import '../../application/models/rules_screen_model.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

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
    // لا يوجد Form ولا validators حالياً (القوائم قيم من الخادم) —
    // بوابة _formKey كانت ترمي NPE مبتلعة داخل try/catch فتقتل الحفظ.
    // عندما تُضاف validators حقيقية تُعاد البوابة إلى هنا.
    setState(() => _isSaving = true);
    try {
      final useCase = ref.read(updateRulesUseCaseProvider);
      final sixteenEligible = model.editableFields.contains(
        'sixteenHourException',
      );
      if ((_sixteenHourException ?? false) && !sixteenEligible) {
        AppFeedback.error(context, context.loc.sixteenHourCondition);
        return;
      }
      final request = RulesScreenUpdateRequest(
        cycleRule: _cycleRule!,
        cargoType: _cargoType!,
        restart: _restart!,
        restBreak: _restBreak!,
        sixteenHourException: sixteenEligible
            ? _sixteenHourException!
            : model.sixteenHourException,
      );

      final result = await useCase.execute(request);
      if (mounted) {
        result.fold(
          (failure) {
            AppFeedback.error(
              context,
              appErrorUserMessage(failure, loc: AppLocalizations.of(context)!),
            );
          },
          (_) {
            AppFeedback.success(context, context.loc.rulesUpdated);
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

  String _serverSetting(
    BuildContext context,
    Map<String, dynamic> settings,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = settings[key];
      if (value == null) continue;
      if (value is bool) {
        return value ? context.loc.allowed : context.loc.forbidden;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return context.loc.notProvidedByServer;
  }

  Widget _buildDropdownOrInfo(
    String fieldName,
    String label,
    String value,
    List<String> options,
    Set<String> editable,
  ) {
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
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: context.styles.body.copyWith(
                  color: context.textSecondary,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: currentValue,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: context.textPrimary,
                  ),
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
                  style: context.styles.body.copyWith(
                    fontSize: AppTypography.bodySize,
                  ),
                  items: options.map((String opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return EldInfoRow(label: label, value: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesScreenAsync = ref.watch(rulesScreenProvider);
    final loc = context.loc;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.rules, style: context.styles.appBarTitle),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: rulesScreenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EldRetryView(
          message: anyErrorUserMessage(err, loc: AppLocalizations.of(context)!),
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
            if (m == 0) return '$h ${loc.hourAbbr}';
            return '$h ${loc.hourAbbr} $m ${loc.minAbbr}';
          }

          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
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
                          Icon(
                            Icons.info_outline,
                            color: context.textPrimary,
                          ),
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
                      if (model.ruleSource.trim().isNotEmpty) ...[
                        _buildDropdownOrInfo(
                          'ruleSource',
                          loc.ruleSource,
                          model.ruleSource,
                          const [],
                          editable,
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],
                      _buildDropdownOrInfo(
                        'cycleRule',
                        loc.cycleRule,
                        model.cycleRule,
                        optionsFor('cycleRule'),
                        editable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildDropdownOrInfo(
                        'cargoType',
                        loc.cargoType,
                        model.cargoType,
                        optionsFor('cargoType'),
                        editable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildDropdownOrInfo(
                        'restart',
                        loc.restartRule,
                        model.restart,
                        optionsFor('restart'),
                        editable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildDropdownOrInfo(
                        'restBreak',
                        loc.restBreakRule,
                        model.restBreak,
                        optionsFor('restBreak'),
                        editable,
                      ),
                      const Divider(height: 1, thickness: 1),

                      if (editable.contains('sixteenHourException'))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  loc.sixteenHourException,
                                  style: context.styles.body.copyWith(
                                    color: context.textSecondary,
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Localizations.localeOf(context).languageCode == 'ar'
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Switch(
                                    value: _sixteenHourException ?? false,
                                    onChanged: (val) {
                                      setState(
                                        () => _sixteenHourException = val,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        EldInfoRow(
                          label: loc.sixteenHourException,
                          value: model.sixteenHourException ? loc.yes : loc.no,
                        ),
                      const Divider(height: 1, thickness: 1),

                      EldInfoRow(
                        label: loc.personalConveyance,
                        value: _serverSetting(
                          context,
                          model.fixedSettings,
                          const [
                            'personalConveyance',
                            'personalConveyanceEnabled',
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      EldInfoRow(
                        label: loc.yardMoves,
                        value: _serverSetting(
                          context,
                          model.fixedSettings,
                          const ['yardMoves', 'yardMoveEnabled'],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      EldInfoRow(
                        label: loc.unlimitedTrailers,
                        value: _serverSetting(
                          context,
                          model.fixedSettings,
                          const [
                            'unlimitedTrailers',
                            'unlimitedTrailerEnabled',
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      EldInfoRow(
                        label: loc.unlimitedShippingDocs,
                        value:
                            _serverSetting(context, model.fixedSettings, const [
                              'unlimitedShippingDocuments',
                              'unlimitedShippingEnabled',
                            ]),
                      ),
                      const Divider(height: 1, thickness: 1),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: AppButton(
                      label: loc.saveButton,
                      type: EldButtonType.send,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : () => _saveRules(model),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info,
                          color: context.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            loc.contactFleetManager,
                            textAlign: TextAlign.center,
                            style: context.styles.body.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          loc.dailyLimits,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      EldInfoRow(
                        label: loc.drivingLimit,
                        value: hours(config.drivingLimitMinutes),
                      ),
                      const Divider(height: 1, thickness: 1),
                      EldInfoRow(
                        label: loc.shiftWindowLimit,
                        value: hours(config.shiftLimitMinutes),
                      ),
                      const Divider(height: 1, thickness: 1),
                      EldInfoRow(
                        label: loc.cycleLimit,
                        value:
                            '${config.cycleLimitHours} / ${config.maxConsecutiveDays}',
                      ),
                      const Divider(height: 1, thickness: 1),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

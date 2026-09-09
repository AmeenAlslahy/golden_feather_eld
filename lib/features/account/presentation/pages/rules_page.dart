import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';

import '../../../../core/services/user_preferences_storage_service.dart';

/// مزود حالة القواعد
final rulesProvider = StateNotifierProvider<RulesNotifier, RulesState>((ref) {
  final prefs = ref.watch(userPreferencesStorageProvider);
  return RulesNotifier(prefs);
});

class RulesState {
  final String cycleRule;
  final String cargoType;
  final bool enable30MinBreak;
  final bool enableShortHaul16Hour;
  final bool enablePersonalConveyance;
  final bool enableYardMoves;

  const RulesState({
    this.cycleRule = 'USA 70/8',
    this.cargoType = 'Property',
    this.enable30MinBreak = true,
    this.enableShortHaul16Hour = false,
    this.enablePersonalConveyance = false,
    this.enableYardMoves = false,
  });

  RulesState copyWith({
    String? cycleRule,
    String? cargoType,
    bool? enable30MinBreak,
    bool? enableShortHaul16Hour,
    bool? enablePersonalConveyance,
    bool? enableYardMoves,
  }) {
    return RulesState(
      cycleRule: cycleRule ?? this.cycleRule,
      cargoType: cargoType ?? this.cargoType,
      enable30MinBreak: enable30MinBreak ?? this.enable30MinBreak,
      enableShortHaul16Hour:
          enableShortHaul16Hour ?? this.enableShortHaul16Hour,
      enablePersonalConveyance:
          enablePersonalConveyance ?? this.enablePersonalConveyance,
      enableYardMoves: enableYardMoves ?? this.enableYardMoves,
    );
  }
}

class RulesNotifier extends StateNotifier<RulesState> {
  final UserPreferencesStorageService _prefs;

  RulesNotifier(this._prefs)
      : super(RulesState(
          cycleRule: _prefs.cycleRule,
          cargoType: _prefs.cargoType,
          enable30MinBreak: _prefs.enable30MinBreak,
          enableShortHaul16Hour: _prefs.enableShortHaul16Hour,
          enablePersonalConveyance: _prefs.enablePersonalConveyance,
          enableYardMoves: _prefs.enableYardMoves,
        ));

  void setCycleRule(String rule) => state = state.copyWith(cycleRule: rule);
  void setCargoType(String type) => state = state.copyWith(cargoType: type);
  void toggle30MinBreak() =>
      state = state.copyWith(enable30MinBreak: !state.enable30MinBreak);
  void toggleShortHaul() => state =
      state.copyWith(enableShortHaul16Hour: !state.enableShortHaul16Hour);
  void togglePersonalConveyance() => state =
      state.copyWith(enablePersonalConveyance: !state.enablePersonalConveyance);
  void toggleYardMoves() =>
      state = state.copyWith(enableYardMoves: !state.enableYardMoves);

  Future<void> save() async {
    await _prefs.setCycleRule(state.cycleRule);
    await _prefs.setCargoType(state.cargoType);
    await _prefs.setEnable30MinBreak(state.enable30MinBreak);
    await _prefs.setEnableShortHaul16Hour(state.enableShortHaul16Hour);
    await _prefs.setEnablePersonalConveyance(state.enablePersonalConveyance);
    await _prefs.setEnableYardMoves(state.enableYardMoves);
  }
}

/// شاشة القواعد
class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = context.loc;

    final cycleOptions = [
      'USA 70/8',
      'USA 60/7',
      'Canada 70/7',
      'Canada 120/14'
    ];
    final cargoOptions = ['Property', 'Passenger'];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== دورة القيادة ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'دورة القيادة' : 'Cycle Rule',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: rules.cycleRule,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: cycleOptions.map((option) {
                      return DropdownMenuItem(
                          value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(rulesProvider.notifier).setCycleRule(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== نوع الشحن ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'نوع الشحن' : 'Cargo Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: rules.cargoType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: cargoOptions.map((option) {
                      return DropdownMenuItem(
                          value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(rulesProvider.notifier).setCargoType(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== خيارات التبديل ==========
            EldCard(
              child: Column(
                children: [
                  _buildSwitch(
                    context,
                    isArabic ? 'استراحة 30 دقيقة' : '30-Minute Break',
                    'FMCSA 49 CFR §395.3',
                    rules.enable30MinBreak,
                    () => ref.read(rulesProvider.notifier).toggle30MinBreak(),
                  ),
                  const Divider(color: AppColors.border),
                  _buildSwitch(
                    context,
                    isArabic
                        ? 'تجاوز 16 ساعة قصيرة المدى'
                        : 'Short Haul 16-Hour Exception',
                    'FMCSA 49 CFR §395.1(o)',
                    rules.enableShortHaul16Hour,
                    () => ref.read(rulesProvider.notifier).toggleShortHaul(),
                  ),
                  const Divider(color: AppColors.border),
                  _buildSwitch(
                    context,
                    isArabic ? 'استخدام شخصي' : 'Personal Conveyance',
                    'FMCSA 49 CFR §395.8',
                    rules.enablePersonalConveyance,
                    () => ref
                        .read(rulesProvider.notifier)
                        .togglePersonalConveyance(),
                  ),
                  const Divider(color: AppColors.border),
                  _buildSwitch(
                    context,
                    isArabic ? 'حركات الساحة' : 'Yard Moves',
                    'FMCSA 49 CFR §395.28',
                    rules.enableYardMoves,
                    () => ref.read(rulesProvider.notifier).toggleYardMoves(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ========== زر الحفظ ==========
            AppButton(
              label: loc.saveButton.toUpperCase(),
              onPressed: () {
                ref.read(rulesProvider.notifier).save();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(isArabic ? '✅ تم حفظ القواعد' : '✅ Rules saved'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    VoidCallback onChanged,
  ) {
    return SwitchListTile(
      title:
          Text(title, style: const TextStyle(fontSize: AppTypography.bodySize)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: AppTypography.smallSize)),
      value: value,
      onChanged: (_) => onChanged(),
      activeThumbColor: AppColors.primaryBlue,
      contentPadding: EdgeInsets.zero,
    );
  }
}

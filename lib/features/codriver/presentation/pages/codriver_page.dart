import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/codriver.dart';
import '../providers/codriver_provider.dart';

class CoDriverPage extends ConsumerStatefulWidget {
  const CoDriverPage({super.key});

  @override
  ConsumerState<CoDriverPage> createState() => _CoDriverPageState();
}

class _CoDriverPageState extends ConsumerState<CoDriverPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final codriverState = ref.watch(codriverProvider);
    final loc = context.loc;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final brightness = Theme.of(context).brightness;
    final bgColor = AppColors.backgroundFor(brightness);
    final surfaceColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final textSecondaryColor = AppColors.textSecondaryFor(brightness);

    final drivers = [CoDriver.none, ...codriverState.availableDrivers];

    // Get current selection name
    final currentSelectedId =
        _selectedId ?? codriverState.selectedCoDriver?.id ?? 'none';
    final selectedDriverName = drivers
        .firstWhere(
          (d) => d.id == currentSelectedId,
          orElse: () => CoDriver.none,
        )
        .name;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.coDriver,
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
      body: codriverState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    context.loc.selectCoDriver,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  AppGap.xs,
                  Text(
                    context.loc.selectYourCoDriver,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  AppGap.xl,

                  // Selector Row
                  InkWell(
                    onTap: () => _showDriverSelectionDialog(context, drivers,
                        currentSelectedId, isArabic, textColor, surfaceColor),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color:
                                    AppColors.borderFor(brightness))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedDriverName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: textColor),
                        ],
                      ),
                    ),
                  ),

                  const AppGap.custom(60),

                  Text(
                    context.loc.switchDrivers,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  AppGap.sm,
                  Text(
                    context.loc.youWillBecomeCoDriver,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),

                  AppGap.xl,

                  // Switch Button
                  AppButton(
                    label: context.loc.switchAction,
                    type: EldButtonType.agree,
                    isLoading: codriverState.isSwitching,
                    onPressed: (codriverState.isSwitching ||
                            codriverState.selectedCoDriver == null)
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(context.loc.confirmSwitch),
                                content: Text(
                                  context.loc.areYouSureYouWant,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                        MaterialLocalizations.of(context)
                                            .cancelButtonLabel),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                        MaterialLocalizations.of(context)
                                            .okButtonLabel),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              await ref
                                  .read(codriverProvider.notifier)
                                  .switchDrivers();
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      // ignore: use_build_context_synchronously
                                      context.loc.rolesSwitchedSuccessfully,
                                    ),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                                // ignore: use_build_context_synchronously
                                context.go('/home');
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
    );
  }

  void _showDriverSelectionDialog(BuildContext context, List<CoDriver> drivers,
      String currentId, bool isArabic, Color textColor, Color surfaceColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Local state for the dialog radio buttons before pressing OK
        String dialogSelectedId = currentId;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              title: Text(
                context.loc.coDriver,
                style:
                    TextStyle(color: textColor, fontWeight: FontWeight.normal),
              ),
              contentPadding: const EdgeInsets.only(top: 16),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return RadioListTile<String>(
                      title: Text(
                        driver.name.toUpperCase(),
                        style: TextStyle(
                          color: dialogSelectedId == driver.id
                              ? AppColors.primaryBlue
                              : textColor,
                          fontSize: 14,
                        ),
                      ),
                      value: driver.id,
                      // ignore: deprecated_member_use
                      groupValue: dialogSelectedId,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setStateDialog(() {
                          dialogSelectedId = value!;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.loc.cancelButton,
                    style: const TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Apply selection
                    setState(() {
                      _selectedId = dialogSelectedId;
                    });
                    final selected =
                        drivers.firstWhere((d) => d.id == dialogSelectedId);
                    ref
                        .read(codriverProvider.notifier)
                        .selectCoDriver(selected);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.loc.okButton,
                    style: const TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

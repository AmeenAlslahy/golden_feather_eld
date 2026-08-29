import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/context_extensions.dart';
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
    final bgColor = AppColors.backgroundForBrightness(brightness);
    final surfaceColor = AppColors.surfaceForBrightness(brightness);
    final textColor = AppColors.textPrimaryForBrightness(brightness);
    final textSecondaryColor = AppColors.textSecondaryForBrightness(brightness);

    final drivers = [CoDriver.none, ...codriverState.availableDrivers];

    // Get current selection name
    final currentSelectedId = _selectedId ?? codriverState.selectedCoDriver?.id ?? 'none';
    final selectedDriverName = drivers.firstWhere(
      (d) => d.id == currentSelectedId,
      orElse: () => CoDriver.none,
    ).name;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.coDriver,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surfaceLight,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surfaceLight),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: codriverState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isArabic ? 'اختر مساعد السائق' : 'Select Co-driver',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isArabic ? 'الرجاء اختيار مساعد السائق الخاص بك' : 'Select your co-driver',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  
                  // Selector Row
                  InkWell(
                    onTap: () => _showDriverSelectionDialog(context, drivers, currentSelectedId, isArabic, textColor, surfaceColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.borderForBrightness(brightness))),
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

                  const SizedBox(height: 60),

                  Text(
                    isArabic ? 'تبديل الأدوار' : 'Switch Drivers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isArabic
                        ? 'ستصبح السائق المساعد. سيبقى السائق المساعد سائقاً.'
                        : 'You will become co-driver. Your co-driver will stay driver.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),

                  // Switch Button
                  AppButton(
                    label: isArabic ? 'تبديل' : 'SWITCH',
                    type: EldButtonType.agree,
                    isLoading: codriverState.isSwitching,
                    onPressed: (codriverState.isSwitching || codriverState.selectedCoDriver == null)
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(isArabic ? 'تأكيد التبديل' : 'Confirm Switch'),
                                content: Text(
                                  isArabic
                                      ? 'هل أنت متأكد من تبديل الأدوار؟'
                                      : 'Are you sure you want to switch roles?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(MaterialLocalizations.of(context).okButtonLabel),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              await ref.read(codriverProvider.notifier).switchDrivers();
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? '✅ تم تبديل الأدوار بنجاح'
                                          : '✅ Roles switched successfully',
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

  void _showDriverSelectionDialog(BuildContext context, List<CoDriver> drivers, String currentId, bool isArabic, Color textColor, Color surfaceColor) {
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
                isArabic ? 'مساعد السائق' : 'Co-driver',
                style: TextStyle(color: textColor, fontWeight: FontWeight.normal),
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
                          color: dialogSelectedId == driver.id ? AppColors.primaryBlue : textColor,
                          fontSize: 14,
                        ),
                      ),
                      value: driver.id,
                      groupValue: dialogSelectedId,
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
                    isArabic ? 'إلغاء' : 'CANCEL',
                    style: const TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Apply selection
                    setState(() {
                      _selectedId = dialogSelectedId;
                    });
                    final selected = drivers.firstWhere((d) => d.id == dialogSelectedId);
                    ref.read(codriverProvider.notifier).selectCoDriver(selected);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    isArabic ? 'موافق' : 'OK',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/account_provider.dart';

/// شاشة معلومات الحساب
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final accountState = ref.watch(accountProvider);
    final account = accountState.accountData;
    
    final loc = context.loc;
    // ignore: unused_local_variable
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final notAvailable = context.loc.notAvailable;

    final availableLanguages = account?.availableLanguages ?? ['English', 'Spanish', 'Arabic'];
    final availableOdometerUnits = account?.availableOdometerUnits ?? ['mi', 'km'];
    
    final currentLanguage = account?.language ?? 'English';
    final currentOdometer = account?.odometer ?? 'mi';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.account,
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
        actions: [
          accountState.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.mdLg),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.surface,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.surface),
                  onPressed: () {
                    ref.read(accountProvider.notifier).fetchMyAccount();
                  },
                ),
        ],
      ),
      drawer: const EldDrawer(),
      body: accountState.isLoading && account == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(accountProvider.notifier).fetchMyAccount(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ========== صورة واسم السائق ==========
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 44,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        AppGap.md,
                        Text(
                          dashboard.driverName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        AppGap.xs,
                        Text(
                          'Driver',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: AppTypography.captionSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppGap.xl,

                  if (accountState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        accountState.error!,
                        style: const TextStyle(color: AppColors.dangerRed),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // ========== معلومات الحساب ==========
                  EldCard(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          context.loc.email1,
                          account?.email ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          context.loc.phone,
                          account?.phone ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          context.loc.license,
                          account?.license.formatted ?? account?.license.number ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          context.loc.carrier,
                          account?.carrier ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          context.loc.mainOffice,
                          account?.mainOfficeAddress ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          context.loc.homeTerminal,
                          account?.homeTerminalAddress ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          context.loc.timeZone,
                          account?.timeZone ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildDropdownRow(
                          context: context,
                          title: context.loc.languageLabel,
                          value: currentLanguage,
                          items: availableLanguages,
                          onChanged: accountState.isLoading ? null : (newValue) async {
                            if (newValue != null && newValue != currentLanguage) {
                              final success = await ref.read(accountProvider.notifier).updatePreferences(
                                language: newValue,
                                odometerUnit: currentOdometer,
                              );
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.loc.languageUpdatedSuccessfully)),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const Divider(color: AppColors.border),
                        _buildDropdownRow(
                          context: context,
                          title: context.loc.odometer,
                          value: currentOdometer,
                          items: availableOdometerUnits,
                          onChanged: accountState.isLoading ? null : (newValue) async {
                            if (newValue != null && newValue != currentOdometer) {
                              final success = await ref.read(accountProvider.notifier).updatePreferences(
                                language: currentLanguage,
                                odometerUnit: newValue,
                              );
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.loc.odometerUnitUpdatedSuccessfully)),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  AppGap.lg,

                  // ========== رسالة تنبيه ==========
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.warningYellow, size: 20),
                        AppGap.hSm,
                        Expanded(
                          child: Text(
                            account?.notice ?? 
                            (context.loc.pleaseContactFleetManagerTo),
                            style: const TextStyle(
                              fontSize: AppTypography.captionSize,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.bodySize,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: AppTypography.bodySize,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required BuildContext context,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    // التأكد من أن القيمة الحالية موجودة في قائمة الخيارات
    final safeValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : '');

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs, // Reduced padding to account for dropdown height
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.bodySize,
              color: AppColors.textSecondary,
            ),
          ),
          DropdownButton<String>(
            value: safeValue.isEmpty ? null : safeValue,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryBlue),
            underline: const SizedBox(),
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: AppTypography.bodySize,
              fontWeight: AppTypography.semiBold,
              color: AppColors.textPrimary, // تأكد من استخدام اللون الصحيح هنا أو استخدام لون النظام
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
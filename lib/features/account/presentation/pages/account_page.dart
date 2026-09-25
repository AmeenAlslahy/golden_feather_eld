import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final notAvailable = isArabic ? 'غير متوفر' : 'N/A';

    final availableLanguages = account?.availableLanguages ?? ['English', 'Spanish', 'Arabic'];
    final availableOdometerUnits = account?.availableOdometerUnits ?? ['mi', 'km'];
    
    final currentLanguage = account?.language ?? 'English';
    final currentOdometer = account?.odometer ?? 'mi';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? loc.account : 'My Account',
          style: context.styles.appBarTitle,
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
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
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
                  if (accountState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        accountState.error!,
                        style: context.styles.error,
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // ========== معلومات الحساب ==========
                  EldCard(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          isArabic ? 'البريد الإلكتروني' : 'Email',
                          account?.email ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'الاسم' : 'Name',
                          dashboard.driverName,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'رقم الهاتف' : 'Phone',
                          account?.phone ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'الرخصة' : 'License',
                          account == null
                              ? notAvailable
                              : (account.license.formatted.contains(',')
                                  ? account.license.formatted
                                  : '${account.license.state}, ${account.license.number}'),
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'الناقل' : 'Carrier',
                          account?.carrier ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'المكتب الرئيسي' : 'Main Office Address',
                          account?.mainOfficeAddress ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'المحطة الرئيسية' : 'Home Terminal Address',
                          account?.homeTerminalAddress ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildInfoRow(
                          context,
                          isArabic ? 'المنطقة الزمنية' : 'Time zone',
                          account?.timeZone ?? notAvailable,
                        ),
                        const Divider(color: AppColors.border),
                        _buildDropdownRow(
                          context: context,
                          title: isArabic ? 'لغة التطبيق' : 'Language',
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
                                    SnackBar(content: Text(isArabic ? 'تم تحديث اللغة بنجاح' : 'Language updated successfully')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const Divider(color: AppColors.border),
                        _buildDropdownRow(
                          context: context,
                          title: isArabic ? 'وحدة المسافة' : 'Odometer',
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
                                    SnackBar(content: Text(isArabic ? 'تم تحديث وحدة المسافة بنجاح' : 'Odometer unit updated successfully')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ========== رسالة تنبيه ==========
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.warningYellow, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            account?.notice ?? 
                            (isArabic
                                ? 'يرجى الاتصال بمدير الأسطول لتغيير معلومات الحساب.'
                                : 'Please contact your fleet manager to change your account information.'),
                            style: context.styles.caption,
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
            style: context.styles.muted,
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.styles.sectionTitle,
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
        vertical: 4.0, // Reduced padding to account for dropdown height
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.styles.muted,
          ),
          DropdownButton<String>(
            value: safeValue.isEmpty ? null : safeValue,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGold),
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

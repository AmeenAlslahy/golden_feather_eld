import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// شاشة معلومات الحساب
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    final userState = ref.watch(authStateProvider);
    final user = userState.user;
    final attributes = user?.attributes ?? {};
    final loc = context.loc;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final notAvailable = isArabic ? 'غير متوفر' : 'N/A';

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
      ),
      drawer: const EldDrawer(),
      body: SingleChildScrollView(
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
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    dashboard.driverName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
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
            const SizedBox(height: AppSpacing.xl),

            // ========== معلومات الحساب ==========
            EldCard(
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    isArabic ? 'اسم المستخدم' : 'Username',
                    user?.username ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'البريد الإلكتروني' : 'Email',
                    user?.email ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'رقم الهاتف' : 'Phone',
                    user?.phone ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'رقم الرخصة' : 'License Number',
                    attributes['licenseNumber']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'الناقل' : 'Carrier',
                    attributes['carrierName']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'رقم USDOT' : 'USDOT Number',
                    attributes['usdotNumber']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'العنوان' : 'Address',
                    attributes['address']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'القسم' : 'Department',
                    attributes['department']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'الرقم الوظيفي' : 'Employee ID',
                    attributes['employeeId']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildInfoRow(
                    context,
                    isArabic ? 'المسمى الوظيفي' : 'Position',
                    attributes['position']?.toString() ?? notAvailable,
                  ),
                  const Divider(color: AppColors.border),
                  _buildDropdownRow(
                    context,
                    isArabic ? 'المنطقة الزمنية' : 'Time Zone',
                    attributes['timezone']?.toString() ?? 'US/Eastern',
                  ),
                  const Divider(color: AppColors.border),
                  _buildDropdownRow(
                    context,
                    isArabic ? 'لغة التطبيق' : 'Language',
                    attributes['language']?.toString() ??
                        (isArabic ? 'العربية' : 'English'),
                  ),
                  const Divider(color: AppColors.border),
                  _buildDropdownRow(
                    context,
                    isArabic ? 'وحدة المسافة' : 'Odometer',
                    attributes['odometerUnit']?.toString() ?? 'mi',
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
                      isArabic
                          ? 'يرجى الاتصال بمدير الأسطول لتغيير المعلومات'
                          : 'Please contact fleet manager to change information',
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
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.bodySize,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
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
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppTypography.bodySize,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.primaryBlue),
            ],
          ),
        ],
      ),
    );
  }
}

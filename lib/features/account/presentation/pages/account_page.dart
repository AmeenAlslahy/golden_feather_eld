import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/account_provider.dart';
import '../../../../core/widgets/app_feedback.dart';

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

    final notAvailable = loc.na;

    final availableLanguages =
        account?.availableLanguages ?? ['English', 'Spanish', 'Arabic'];
    final availableOdometerUnits =
        account?.availableOdometerUnits ?? ['mi', 'km'];

    final currentLanguage = account?.language ?? 'English';
    final currentOdometer = account?.odometer ?? 'mi';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.account, style: context.styles.appBarTitle),
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
              onRefresh: () =>
                  ref.read(accountProvider.notifier).fetchMyAccount(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface, // Typically white
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (accountState.error != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            accountState.error!,
                            style: context.styles.error,
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // ========== معلومات الحساب ==========
                      _buildInfoRow(
                        context,
                        loc.email1,
                        account?.email ?? notAvailable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.sortByName,
                        dashboard.driverName,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.phone,
                        account?.phone ?? notAvailable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.license,
                        account == null
                            ? notAvailable
                            : (account.license.formatted.contains(',')
                                  ? account.license.formatted
                                  : '${account.license.state}, ${account.license.number}'),
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.carrier,
                        account?.carrier ?? notAvailable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.mainOfficeAddress,
                        account?.mainOfficeAddress ?? notAvailable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.homeTerminalAddress,
                        account?.homeTerminalAddress ?? notAvailable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildInfoRow(
                        context,
                        loc.timeZone,
                        account?.timeZone ?? notAvailable,
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildDropdownRow(
                        context: context,
                        title: loc.languageLabel,
                        value: currentLanguage,
                        items: availableLanguages,
                        onChanged: accountState.isLoading
                            ? null
                            : (newValue) async {
                                if (newValue != null &&
                                    newValue != currentLanguage) {
                                  final success = await ref
                                      .read(accountProvider.notifier)
                                      .updatePreferences(
                                        language: newValue,
                                        odometerUnit: currentOdometer,
                                      );
                                  if (context.mounted) {
                                    if (success) {
                                      AppFeedback.success(
                                        context,
                                        loc.languageUpdatedSuccessfully,
                                      );
                                    }
                                  }
                                }
                              },
                      ),
                      const Divider(height: 1, thickness: 1),
                      _buildDropdownRow(
                        context: context,
                        title: loc.odometer,
                        value: currentOdometer,
                        items: availableOdometerUnits,
                        onChanged: accountState.isLoading
                            ? null
                            : (newValue) async {
                                if (newValue != null &&
                                    newValue != currentOdometer) {
                                  final success = await ref
                                      .read(accountProvider.notifier)
                                      .updatePreferences(
                                        language: currentLanguage,
                                        odometerUnit: newValue,
                                      );
                                  if (context.mounted) {
                                    if (success) {
                                      AppFeedback.success(
                                        context,
                                        loc.odometerUnitUpdatedSuccessfull,
                                      );
                                    }
                                  }
                                }
                              },
                      ),
                      const Divider(height: 1, thickness: 1),

                      const SizedBox(height: 48),

                      // ========== رسالة تنبيه ==========
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
                              color: AppColors.textSecondaryFor(
                                Theme.of(context).brightness,
                              ),
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                account?.notice ??
                                    (loc.pleaseContactYourFleetManagerTo),
                                style: context.styles.body.copyWith(
                                  color: AppColors.textSecondaryFor(
                                    Theme.of(context).brightness,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.styles.body.copyWith(
                color: context.styles.subtitle.color,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: context.styles.body.copyWith(
                color: context.styles.body.color,
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
    final safeValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : '');

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0, // Reduced padding to account for dropdown height
        horizontal: 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: context.styles.body.copyWith(
                color: context.styles.subtitle.color,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safeValue.isEmpty ? null : safeValue,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: context.styles.body.color,
                ),
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: AppTypography.bodySize,
                  color: context.styles.body.color,
                ),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

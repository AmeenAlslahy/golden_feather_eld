import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/eld_dropdown_row.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../domain/account/driver_account.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/account_provider.dart';
import '../utils/account_display.dart';

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
      if (mounted) {
        ref.read(accountProvider.notifier).fetchMyAccount();
      }
    });
  }

  Future<void> _onLanguageChanged({
    required BuildContext context,
    required String? newValue,
    required String currentLanguage,
    required String currentOdometer,
  }) async {
    if (newValue == null || newValue == currentLanguage) return;

    final code = languageCodeForDisplayName(newValue);
    final success = await ref
        .read(accountProvider.notifier)
        .updatePreferences(language: newValue, odometerUnit: currentOdometer);

    if (!context.mounted) return;
    final loc = context.loc;
    if (success) {
      if (code != null) {
        ref.read(localeProvider.notifier).setLocale(code);
      }
      AppFeedback.success(context, loc.languageUpdatedSuccessfully);
    } else {
      final err = ref.read(accountProvider).error;
      if (err != null) {
        AppFeedback.error(context, context.translateErrorKey(err));
      }
    }
  }

  Future<void> _onOdometerChanged({
    required BuildContext context,
    required String? newValue,
    required String currentLanguage,
    required String currentOdometer,
  }) async {
    if (newValue == null || newValue == currentOdometer) return;

    final success = await ref
        .read(accountProvider.notifier)
        .updatePreferences(language: currentLanguage, odometerUnit: newValue);

    if (!context.mounted) return;
    final loc = context.loc;
    if (success) {
      AppFeedback.success(context, loc.odometerUnitUpdatedSuccessfull);
    } else {
      final err = ref.read(accountProvider).error;
      if (err != null) {
        AppFeedback.error(context, context.translateErrorKey(err));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final account = accountState.accountData;
    final user = ref.watch(authStateProvider.select((s) => s.user));

    final loc = context.loc;
    final notAvailable = loc.na;
    final driverName = (user?.fullName.isNotEmpty == true)
        ? user!.fullName
        : notAvailable;

    final availableLanguages =
        account?.availableLanguages ?? DriverAccount.defaultAvailableLanguages;
    final availableOdometerUnits =
        account?.availableOdometerUnits ??
        DriverAccount.defaultAvailableOdometerUnits;

    final currentLocale = ref.watch(localeProvider);
    final currentLanguage = languageDisplayNameForCode(
      currentLocale.languageCode,
    );
    final currentOdometer = account?.odometer ??
        (availableOdometerUnits.isNotEmpty
            ? availableOdometerUnits.first
            : 'mi');

    final accEmail = account?.email;
    final userEmail = user?.email;
    final emailValue = (accEmail != null && accEmail.isNotEmpty)
        ? accEmail
        : ((userEmail != null && userEmail.isNotEmpty)
            ? userEmail
            : notAvailable);

    final accPhone = account?.phone;
    final phoneValue = (accPhone != null && accPhone.isNotEmpty)
        ? accPhone
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.account, style: context.styles.appBarTitle),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          accountState.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      width: AppSpacing.iconMedium,
                      height: AppSpacing.iconMedium,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (accountState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.compact,
                        ),
                        child: Text(
                          context.translateErrorKey(accountState.error!),
                          style: context.styles.error,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    EldInfoRow(label: loc.email1, value: emailValue),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(label: loc.driverName, value: driverName),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(label: loc.phone, value: phoneValue),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(
                      label: loc.license,
                      value: account == null
                          ? notAvailable
                          : licenseDisplayText(account.license),
                    ),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(
                      label: loc.carrier,
                      value: account?.carrier ?? notAvailable,
                    ),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(
                      label: loc.mainOfficeAddress,
                      value: account?.mainOfficeAddress ?? notAvailable,
                    ),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(
                      label: loc.homeTerminalAddress,
                      value: account?.homeTerminalAddress ?? notAvailable,
                    ),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldInfoRow(
                      label: loc.timeZone,
                      value: account?.timeZone ?? notAvailable,
                    ),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldDropdownRow(
                      label: loc.languageLabel,
                      value: currentLanguage,
                      items: availableLanguages,
                      enabled: !accountState.isLoading,
                      onChanged: (newValue) => _onLanguageChanged(
                        context: context,
                        newValue: newValue,
                        currentLanguage: currentLanguage,
                        currentOdometer: currentOdometer,
                      ),
                    ),
                    Divider(
                      color: context.border,
                      height: AppSpacing.dividerHeight,
                    ),
                    EldDropdownRow(
                      label: loc.odometer,
                      value: currentOdometer,
                      items: availableOdometerUnits,
                      enabled: !accountState.isLoading,
                      onChanged: (newValue) => _onOdometerChanged(
                        context: context,
                        newValue: newValue,
                        currentLanguage: currentLanguage,
                        currentOdometer: currentOdometer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info,
                          color: context.textSecondary,
                          size: AppSpacing.iconSmall,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            account?.notice ??
                                loc.pleaseContactYourFleetManagerTo,
                            textAlign: TextAlign.center,
                            style: context.styles.caption.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../domain/account/driver_account.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../utils/account_display.dart';
import 'account_provider.dart';

/// حالة العرض المخصصة لشاشة الحساب — تفصل تجهيز البيانات عن شاشات العرض.
class AccountUiState {
  final String email;
  final String driverName;
  final String phone;
  final String license;
  final String carrier;
  final String mainOfficeAddress;
  final String homeTerminalAddress;
  final String timeZone;
  final String currentLanguage;
  final List<String> availableLanguages;
  final String currentOdometer;
  final List<String> availableOdometerUnits;
  final String notice;
  final bool isLoading;
  final String? error;

  const AccountUiState({
    required this.email,
    required this.driverName,
    required this.phone,
    required this.license,
    required this.carrier,
    required this.mainOfficeAddress,
    required this.homeTerminalAddress,
    required this.timeZone,
    required this.currentLanguage,
    required this.availableLanguages,
    required this.currentOdometer,
    required this.availableOdometerUnits,
    required this.notice,
    required this.isLoading,
    this.error,
  });
}

/// موفر حالة العرض لشاشة الحساب — يعزل المنطق عن واجهة المستخدم بالكامل.
final accountUiStateProvider = Provider<AccountUiState>((ref) {
  final accountState = ref.watch(accountProvider);
  final account = accountState.accountData;
  final user = ref.watch(authStateProvider.select((s) => s.user));
  final currentLocale = ref.watch(localeProvider);

  final availableLanguages =
      account?.availableLanguages ?? DriverAccount.defaultAvailableLanguages;
  final availableOdometerUnits =
      account?.availableOdometerUnits ??
      DriverAccount.defaultAvailableOdometerUnits;

  final currentLanguage = languageDisplayNameForCode(
    currentLocale.languageCode,
  );
  final currentOdometer =
      account?.odometer ??
      (availableOdometerUnits.isNotEmpty ? availableOdometerUnits.first : 'mi');

  final emailValue = (account != null && account.email.isNotEmpty)
      ? account.email
      : (user?.email.isNotEmpty == true ? user!.email : 'N/A');

  final driverName = (user != null && user.fullName.isNotEmpty)
      ? user.fullName
      : 'N/A';

  final phoneValue = account?.phone ?? '';
  final licenseValue = account == null
      ? 'N/A'
      : licenseDisplayText(account.license);

  return AccountUiState(
    email: emailValue,
    driverName: driverName,
    phone: phoneValue,
    license: licenseValue,
    carrier: account?.carrier ?? 'N/A',
    mainOfficeAddress: account?.mainOfficeAddress ?? 'N/A',
    homeTerminalAddress: account?.homeTerminalAddress ?? 'N/A',
    timeZone: account?.timeZone ?? 'N/A',
    currentLanguage: currentLanguage,
    availableLanguages: availableLanguages,
    currentOdometer: currentOdometer,
    availableOdometerUnits: availableOdometerUnits,
    notice: account?.notice ?? '',
    isLoading: accountState.isLoading,
    error: accountState.error,
  );
});

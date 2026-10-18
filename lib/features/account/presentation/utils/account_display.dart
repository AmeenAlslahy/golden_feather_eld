import '../../../../domain/account/driver_account.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/models/rules_screen_model.dart';

String formatHoursMinutes(AppLocalizations loc, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '$h ${loc.hourAbbr}';
  return '$h ${loc.hourAbbr} $m ${loc.minAbbr}';
}

String serverSettingText(
  AppLocalizations loc,
  RulesScreenModel model,
  List<String> keys,
) {
  final allowed = model.tryIsSettingAllowed(keys);
  if (allowed != null) return allowed ? loc.allowed : loc.forbidden;
  return model.firstSettingDisplayText(keys) ?? loc.notProvidedByServer;
}

String licenseDisplayText(LicenseInfo license) {
  if (license.formatted.contains(',')) return license.formatted;
  return '${license.state}, ${license.number}';
}

String languageDisplayNameForCode(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return 'Arabic';
    case 'es':
      return 'Spanish';
    default:
      return 'English';
  }
}

String? languageCodeForDisplayName(String displayName) {
  switch (displayName.trim().toLowerCase()) {
    case 'arabic':
    case 'العربية':
      return 'ar';
    case 'spanish':
    case 'español':
    case 'espanol':
      return 'es';
    case 'english':
      return 'en';
    default:
      return null;
  }
}

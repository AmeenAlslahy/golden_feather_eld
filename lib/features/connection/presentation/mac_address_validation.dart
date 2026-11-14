import '../../../../l10n/app_localizations.dart';

/// Field error for the ELD MAC input, or null when acceptable.
/// Only non-empty is enforced: the identifier printed on real devices is not
/// always colon-separated, so the format is not rejected client-side.
String? macAddressError(String? value, {required AppLocalizations loc}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return loc.macAddressRequired;
  }
  return null;
}

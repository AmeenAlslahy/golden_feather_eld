import '../../../../l10n/app_localizations.dart';

/// Field error for the ELD MAC input, or null when acceptable.
/// Only "required" is enforced: the identifier printed on real devices is not
/// always colon-separated, so the format is not rejected client-side.
///
/// Presentation-layer (يحتاج l10n) — كان في domain/ وخرق طبقة النماذج.
String? macAddressError(String? value, {required AppLocalizations loc}) {
  if ((value?.trim() ?? '').isEmpty) {
    return loc.macAddressRequired;
  }
  return null;
}

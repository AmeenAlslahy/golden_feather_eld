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

/// Normalizes a user-entered MAC address or hardware identifier into standard
/// uppercase colon-separated format (e.g. AA:BB:CC:DD:EE:FF).
///
/// Returns null if the value is not a 12-character hex string or formatted MAC,
/// allowing callers to fall back to name/serial-based BLE device search.
String? normalizeMacAddress(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  final stripped = trimmed.replaceAll(RegExp(r'[:\-\s]'), '').toUpperCase();
  if (stripped.length == 12 && RegExp(r'^[0-9A-F]{12}$').hasMatch(stripped)) {
    return List.generate(
      6,
      (i) => stripped.substring(i * 2, i * 2 + 2),
    ).join(':');
  }
  if (RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(trimmed)) {
    return trimmed.toUpperCase().replaceAll('-', ':');
  }
  return null;
}

import '../../../../l10n/app_localizations.dart';

/// قاعدة صحة رابط الخادم — HTTPS فقط.
///
/// الرابط يُحفظ كأصل الخادم (origin) لكل الطلبات الآمنة، وقبول `http`
/// يعني تمرير الاعتماد وبيانات الموقع فوق قناة نصية مكشوفة (49 CFR
/// Part 395 يوجب حماية سجلات HOS من العبث والاعتراض).
bool isHttpsServerUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  return uri != null &&
      uri.hasAuthority &&
      uri.host.isNotEmpty &&
      uri.scheme.toLowerCase() == 'https';
}

/// Field error for the server URL input, or null when acceptable.
///
/// Presentation-layer (يحتاج l10n) — نفس نمط `mac_address_validation.dart`.
String? serverUrlError(String? value, {required AppLocalizations loc}) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return loc.enterServerUrl;
  }
  if (!isHttpsServerUrl(raw)) {
    return loc.invalidServerUrl;
  }
  return null;
}

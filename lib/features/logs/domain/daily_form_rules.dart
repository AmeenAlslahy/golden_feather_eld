/// Single source of the daily-form list rules (SRS 5.5–5.13).
///
/// The Form tab keeps trailers and shipping documents as one comma-separated
/// string on the dashboard state; the Trailers / Shipping Documents pages and
/// the SAVE payload all go through these helpers so they never disagree.
library;
import '../../../../l10n/app_localizations.dart';

const _placeholders = {'', 'None', '-', 'none'};

/// Splits the stored form value into its items, dropping placeholders.
List<String> splitFormList(String? raw) {
  if (raw == null) return const [];
  return raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => !_placeholders.contains(e))
      .toList();
}

/// Joins items back into the stored form value (`None` when empty).
String joinFormList(List<String> items) =>
    items.isEmpty ? 'None' : items.join(', ');

/// `UpdateDailyFormRequest.trailers[].trailerNumber` rule.
String? trailerNumberError(String value, AppLocalizations loc) {
  final v = value.trim();
  if (v.isEmpty) {
    return loc.enterTrailerNumber;
  }
  if (v.length > 50 || !RegExp(r'^[A-Za-z0-9-]+$').hasMatch(v)) {
    return loc.trailerNumberFormatError;
  }
  return null;
}

/// `UpdateDailyFormRequest.shippingDocuments[].documentNumber` rule.
String? shippingDocumentError(String value, AppLocalizations loc) {
  final v = value.trim();
  if (v.isEmpty) {
    return loc.enterDocumentNumber;
  }
  if (v.length > 100) {
    return loc.documentNumberTooLong;
  }
  if (v.contains(',')) {
    return loc.oneDocumentAtATime;
  }
  return null;
}

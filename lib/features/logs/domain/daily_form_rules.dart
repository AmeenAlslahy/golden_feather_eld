/// Single source of the daily-form list rules (SRS 5.5–5.13).
///
/// The Form tab keeps trailers and shipping documents as one comma-separated
/// string on the dashboard state; the Trailers / Shipping Documents pages and
/// the SAVE payload all go through these helpers so they never disagree.
library;

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
String? trailerNumberError(String value, {required bool isArabic}) {
  final v = value.trim();
  if (v.isEmpty) {
    return isArabic ? 'أدخل رقم المقطورة.' : 'Enter the trailer number.';
  }
  if (v.length > 50 || !RegExp(r'^[A-Za-z0-9-]+$').hasMatch(v)) {
    return isArabic
        ? 'رقم المقطورة: أحرف وأرقام وشرطات فقط (حتى 50).'
        : 'Trailer number must be letters, numbers, or hyphens (max 50).';
  }
  return null;
}

/// `UpdateDailyFormRequest.shippingDocuments[].documentNumber` rule.
String? shippingDocumentError(String value, {required bool isArabic}) {
  final v = value.trim();
  if (v.isEmpty) {
    return isArabic ? 'أدخل رقم المستند.' : 'Enter the document number.';
  }
  if (v.length > 100) {
    return isArabic
        ? 'رقم مستند الشحن طويل جداً (حتى 100).'
        : 'Shipping document number is too long (max 100).';
  }
  if (v.contains(',')) {
    return isArabic
        ? 'أدخل مستنداً واحداً في كل مرة (بدون فاصلة).'
        : 'Enter one document at a time (no comma).';
  }
  return null;
}

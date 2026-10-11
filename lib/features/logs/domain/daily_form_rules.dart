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

/// أحرف مسموحة في التسميات: حروف كل اللغات (تشمل العربية) + أرقام +
/// مسافة + فواصل بسيطة فقط. النقطة والفاصلة وعلامات الرياضيات والأقواس
/// مرفوضة — والفاصلة (`,`) فاصل عناصر أصلاً. [extra] يضيف رموزاً
/// خاصة بنوع (مثل `/` لأرقام وثائق الشحن BOL).
final RegExp _labelBase = RegExp(r'^[\p{L}\p{N}\s\-_#]+$', unicode: true);
final RegExp _labelWithSlash =
    RegExp(r'^[\p{L}\p{N}\s\-_#/]+$', unicode: true);

/// الجوهر المطلوب: حرف أو رقم واحد على الأقل — "..." أو ",,," مرفوضة.
final RegExp _labelSubstance =
    RegExp(r'[\p{L}\p{N}]', unicode: true);

/// نص حر (موقع/سبب): حروف وأرقام كل اللغات + ترقيم نصي أساسي فقط.
/// تُرفض علامات الرياضيات (`= + * / \ < > | ~ ` ^ % $ &`) والأقواس
/// والرموز (`()[]{}`) — والنص المكون من ترقيم خالص مرفوض لانعدام الجوهر.
final RegExp _freeTextChars = RegExp(
  r'^[\p{L}\p{N}\s.,;:!?\x22\x27\-—_#]+$',
  unicode: true,
);

/// يتحقق من تسمية (مقطورة/وثيقة): الع set المسموح + الجوهر + الطول.
bool isFormLabelValid(String value, int maxLength, {bool allowSlash = false}) {
  final v = value.trim();
  if (v.isEmpty || v.length > maxLength) return false;
  if (v.contains(',')) return false;
  final allowed = allowSlash ? _labelWithSlash : _labelBase;
  return allowed.hasMatch(v) && _labelSubstance.hasMatch(v);
}

/// يتحقق من نص حر (موقع/سبب): مسموح + جوهر (حرف/رقم واحد على الأقل).
bool isFreeTextValid(String value, {int maxLength = 200}) {
  final v = value.trim();
  if (v.isEmpty || v.length > maxLength) return false;
  return _freeTextChars.hasMatch(v) && _labelSubstance.hasMatch(v);
}

enum TrailerValidationError {
  empty,
  tooLong,
  formatError,
}

enum ShippingDocValidationError {
  empty,
  tooLong,
  containsComma,
  formatError,
}

/// يتحقق من صحة رقم المقطورة ويعيد رمز الخطأ في المجال أو null إذا كان صحيحاً.
TrailerValidationError? validateTrailerNumber(String value) {
  final v = value.trim();
  if (v.isEmpty) return TrailerValidationError.empty;
  if (!isFormLabelValid(v, 50)) return TrailerValidationError.formatError;
  return null;
}

/// يتحقق من صحة وثيقة الشحن ويعيد رمز الخطأ في المجال أو null إذا كانت صحيحة.
ShippingDocValidationError? validateShippingDocument(String value) {
  final v = value.trim();
  if (v.isEmpty) return ShippingDocValidationError.empty;
  if (v.length > 100) return ShippingDocValidationError.tooLong;
  if (v.contains(',')) return ShippingDocValidationError.containsComma;
  if (!isFormLabelValid(v, 100, allowSlash: true)) {
    return ShippingDocValidationError.formatError;
  }
  return null;
}

/// `UpdateDailyFormRequest.trailers[].trailerNumber` rule.
String? trailerNumberError(String value, dynamic loc) {
  final err = validateTrailerNumber(value);
  if (err == null) return null;
  switch (err) {
    case TrailerValidationError.empty:
      return (loc?.enterTrailerNumber as String?) ?? 'Enter trailer number';
    case TrailerValidationError.tooLong:
    case TrailerValidationError.formatError:
      return (loc?.trailerNumberFormatError as String?) ?? 'Invalid trailer number format';
  }
}

/// `UpdateDailyFormRequest.shippingDocuments[].documentNumber` rule.
String? shippingDocumentError(String value, dynamic loc) {
  final err = validateShippingDocument(value);
  if (err == null) return null;
  switch (err) {
    case ShippingDocValidationError.empty:
      return (loc?.enterDocumentNumber as String?) ?? 'Enter document number';
    case ShippingDocValidationError.tooLong:
      return (loc?.documentNumberTooLong as String?) ?? 'Document number too long';
    case ShippingDocValidationError.containsComma:
      return (loc?.oneDocumentAtATime as String?) ?? 'One document at a time';
    case ShippingDocValidationError.formatError:
      return (loc?.shippingDocumentFormatError as String?) ?? 'Invalid document number format';
  }
}

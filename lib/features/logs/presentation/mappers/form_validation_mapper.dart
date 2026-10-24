import '../../../../l10n/app_localizations.dart';
import '../../domain/daily_form_rules.dart';

/// Maps domain validation codes to localized UI messages.
///
/// The domain owns the rules; this mapper owns presentation strings so the
/// rules stay free of `AppLocalizations`.
String? trailerNumberError(String value, AppLocalizations loc) {
  final error = validateTrailerNumber(value);
  if (error == null) return null;
  return switch (error) {
    TrailerValidationError.empty => loc.enterTrailerNumber,
    TrailerValidationError.tooLong => loc.trailerNumberTooLong,
    TrailerValidationError.formatError => loc.trailerNumberFormatError,
  };
}

/// Maps domain validation codes to localized UI messages.
String? shippingDocumentError(String value, AppLocalizations loc) {
  final error = validateShippingDocument(value);
  if (error == null) return null;
  return switch (error) {
    ShippingDocValidationError.empty => loc.enterDocumentNumber,
    ShippingDocValidationError.tooLong => loc.documentNumberTooLong,
    ShippingDocValidationError.containsComma => loc.oneDocumentAtATime,
    ShippingDocValidationError.formatError => loc.shippingDocumentFormatError,
  };
}

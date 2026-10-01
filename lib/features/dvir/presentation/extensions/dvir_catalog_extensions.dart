import '../../../../l10n/app_localizations.dart';
import '../../domain/dvir_catalog.dart';

/// Presentation-layer extension that adds l10n-aware label to [DvirCatalogItem].
/// Kept here (not in Domain) because AppLocalizations is a UI concern.
extension DvirCatalogItemL10n on DvirCatalogItem {
  String label(AppLocalizations loc) =>
      loc.localeName == 'ar' && (nameAr?.trim().isNotEmpty ?? false) ? nameAr! : name;
}

import 'package:equatable/equatable.dart';

/// One §396.11 catalog item from `GET /eld/dvir/catalog`.
class DvirCatalogItem extends Equatable {
  final String code;
  final String name;
  final String? nameAr;
  final String category;
  final bool mandatory;
  final bool critical;

  const DvirCatalogItem({
    required this.code,
    required this.name,
    this.nameAr,
    this.category = '',
    this.mandatory = false,
    this.critical = false,
  });

  /// Returns the Arabic name if non-empty, otherwise the English name.
  /// For full l10n-aware label, use DvirCatalogItemL10n.label(loc) in Presentation.
  String get displayName =>
      (nameAr?.trim().isNotEmpty ?? false) ? nameAr! : name;

  @override
  List<Object?> get props => [code, name, nameAr, category, mandatory, critical];
}

/// A catalog item the driver marked as defective, with an optional note.
class DvirDefectSelection extends Equatable {
  final DvirCatalogItem item;
  final String? description;

  const DvirDefectSelection({required this.item, this.description});

  /// Wire shape of `DvirDefectItem` on `InsertDvirRequest`.
  Map<String, dynamic> toWire() {
    final note = description?.trim() ?? '';
    return {
      'itemCode': item.code,
      'itemName': item.name,
      'category': item.category,
      'safetyAffecting': item.critical,
      if (note.isNotEmpty) 'description': note,
    };
  }

  @override
  List<Object?> get props => [item, description];
}

/// Reads the catalog from the live envelope. Returns null when the body is unreadable.
/// Accepts the observed keys (`code`/`name`/`nameAr`/`statutoryMandatory`/`criticalSafety`)
/// and the schema keys (`itemCode`/`itemName`/`safetyAffecting`).
List<DvirCatalogItem>? parseDvirCatalog(Object? body) {
  final list = _findList(body);
  if (list == null) return null;
  final items = <DvirCatalogItem>[];
  for (final raw in list) {
    if (raw is! Map) continue;
    final code = _text(raw['code'] ?? raw['itemCode']);
    final name = _text(raw['name'] ?? raw['itemName']);
    if (code == null || name == null) continue;
    items.add(DvirCatalogItem(
      code: code,
      name: name,
      nameAr: _text(raw['nameAr']),
      category: _text(raw['category']) ?? '',
      mandatory: raw['statutoryMandatory'] == true || raw['mandatory'] == true,
      critical: raw['criticalSafety'] == true ||
          raw['safetyAffecting'] == true ||
          raw['outOfService'] == true,
    ));
  }
  return items;
}

List<dynamic>? _findList(Object? body) {
  if (body is List) return body;
  if (body is! Map) return null;
  for (final key in const ['items', 'catalog', 'defects', 'data', 'content']) {
    final value = body[key];
    if (value is List) return value;
    if (value is Map) {
      final nested = _findList(value);
      if (nested != null) return nested;
    }
  }
  return null;
}

String? _text(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

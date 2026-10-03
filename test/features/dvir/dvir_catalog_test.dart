import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/features/dvir/data/mappers/dvir_mappers.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/presentation/extensions/dvir_catalog_extensions.dart';

void main() {
  test('parses the live catalog keys and the schema keys', () {
    final items = parseDvirCatalog({
      'items': [
        {
          'code': 'BRAKES_SERVICE',
          'name': 'Service brakes',
          'nameAr': 'مكابح الخدمة',
          'category': 'REGULATORY_MINIMUM',
          'statutoryMandatory': true,
          'criticalSafety': true,
        },
        {'itemCode': 'HORN', 'itemName': 'Horn', 'safetyAffecting': false},
        {'name': 'no code — skipped'},
      ],
    });

    expect(items, isNotNull);
    expect(items!.length, 2);
    expect(items.first.code, 'BRAKES_SERVICE');
    expect(items.first.label(lookupAppLocalizations(const Locale('ar'))), 'مكابح الخدمة');
    expect(items.first.critical, isTrue);
    expect(items.last.code, 'HORN');
    expect(items.last.label(lookupAppLocalizations(const Locale('ar'))), 'Horn');
  });

  test('an unreadable body is null, not an empty catalog', () {
    expect(parseDvirCatalog({'status': 'ok'}), isNull);
    expect(parseDvirCatalog('x'), isNull);
    expect(parseDvirCatalog(const []), isEmpty);
  });

  test('a catalog pick goes on the wire as a DvirDefectItem', () {
    const pick = DvirDefectSelection(
      item: DvirCatalogItem(
        code: 'TIRES',
        name: 'Tires',
        category: 'REGULATORY_MINIMUM',
        critical: true,
      ),
      description: 'left front worn',
    );

    final wire = defectSelectionToWire(pick);

    expect(wire['itemCode'], 'TIRES');
    expect(wire['safetyAffecting'], isTrue);
    expect(wire['description'], 'left front worn');
  });

  test('an empty note is omitted from the wire item', () {
    const pick = DvirDefectSelection(
      item: DvirCatalogItem(code: 'HORN', name: 'Horn'),
      description: '   ',
    );
    expect(defectSelectionToWire(pick).containsKey('description'), isFalse);
  });
}

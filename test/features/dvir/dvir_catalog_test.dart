import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_submission.dart';

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

  test('catalog picks go on the wire as DvirDefectItem before free text', () {
    const pick = DvirDefectSelection(
      item: DvirCatalogItem(
        code: 'TIRES',
        name: 'Tires',
        category: 'REGULATORY_MINIMUM',
        critical: true,
      ),
      description: 'left front worn',
    );

    final defects = dvirDefects(
      vehicle: 'mirror cracked',
      catalog: [pick.toWire()],
    );

    expect(defects.length, 2);
    expect(defects.first['itemCode'], 'TIRES');
    expect(defects.first['safetyAffecting'], isTrue);
    expect(defects.first['description'], 'left front worn');
    expect(defects.last['itemName'], 'Vehicle defect');
  });

  test('an empty note is omitted from the wire item', () {
    const pick = DvirDefectSelection(
      item: DvirCatalogItem(code: 'HORN', name: 'Horn'),
      description: '   ',
    );
    expect(pick.toWire().containsKey('description'), isFalse);
  });
}

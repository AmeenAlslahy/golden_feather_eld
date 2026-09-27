import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_list_summary.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';

DvirReport _report({
  required String id,
  bool hasDefects = false,
  bool certified = false,
  bool outOfService = false,
  String? signature,
}) {
  return DvirReport(
    id: id,
    type: InspectionType.preTrip,
    date: DateTime(2026, 9, 24),
    driverName: 'A',
    vehicleId: '1001',
    items: const [],
    hasDefects: hasDefects,
    certified: certified,
    outOfService: outOfService,
    signature: signature,
  );
}

void main() {
  test('empty list is four zeros', () {
    final summary = summarizeDvirReports(const []);
    expect(summary.total, 0);
    expect(summary.openDefects, 0);
    expect(summary.signed, 0);
    expect(summary.outOfService, 0);
  });

  test('counts come from the loaded reports only', () {
    final summary = summarizeDvirReports([
      _report(id: '1', hasDefects: true),
      _report(id: '2', certified: true, signature: 'x'),
      _report(id: '3', outOfService: true, hasDefects: true),
    ]);
    expect(summary.total, 3);
    expect(summary.openDefects, 2);
    expect(summary.signed, 1);
    expect(summary.outOfService, 1);
  });
}

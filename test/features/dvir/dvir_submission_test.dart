import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/dvir/data/mappers/dvir_mappers.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_signature.dart';

void main() {
  test('a local signature id is not sent', () {
    expect(dvirSignatureData(null), isNull);
    expect(dvirSignatureData(const []), isNull);
    expect(dvirSignatureData([1, 2, 3]), 'AQID');
    expect(
      buildDvirCreateBody(
        driverId: 106,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'signature_1',
        inspectionTime: '2026-09-23T00:00:00.000Z',
      ),
      isNull,
    );
  });

  test('create body keeps the selected status and the defect text', () {
    final body = buildDvirCreateBody(
      driverId: 106,
      uniqueId: 'TRUCK-1',
      status: 'Vehicle Condition Satisfactory',
      signatureData: 'AQID',
      inspectionTime: '2026-09-23T00:00:00.000Z',
      vehicleDefects: 'brake leak',
      trailerDefects: 'light out',
    );
    expect(body?['driverId'], 106);
    expect(body?['status'], 'Vehicle Condition Satisfactory');
    expect(body?['signatureData'], 'AQID');
    expect(body?['defects'], [
      {'itemName': 'Vehicle defect', 'category': 'VEHICLE', 'description': 'brake leak'},
      {'itemName': 'Trailer defect', 'category': 'TRAILER', 'description': 'light out'},
    ]);
  });

  test('missing driver or vehicle does not invent an id', () {
    expect(
      buildDvirCreateBody(
        driverId: 0,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
      ),
      isNull,
    );
    expect(
      buildDvirCreateBody(
        driverId: 106,
        uniqueId: 'No Vehicle',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
      ),
      isNull,
    );
  });
}

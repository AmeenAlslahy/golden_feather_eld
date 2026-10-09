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
        deviceId: 7,
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
      deviceId: 7,
      uniqueId: 'TRUCK-1',
      status: 'Vehicle Condition Satisfactory',
      signatureData: 'AQID',
      inspectionTime: '2026-09-23T00:00:00.000Z',
      vehicleDefects: 'brake leak',
      trailerDefects: 'light out',
    );
    expect(body?['driverId'], 106);
    expect(body?['deviceId'], 7);
    // DVIR-09: عيوب على السلك تُصالح الحالة إلى Has Defects.
    expect(body?['status'], 'Has Defects');
    expect(body?['signatureData'], 'AQID');
    expect(body?['vehicle']['detects'], [
      {'itemName': 'Vehicle defect', 'description': 'brake leak'},
    ]);
  });

  test('satisfactory status passes through when there are no defects', () {
    final body = buildDvirCreateBody(
      driverId: 106,
      deviceId: 7,
      uniqueId: 'TRUCK-1',
      status: 'Vehicle Condition Satisfactory',
      signatureData: 'AQID',
      inspectionTime: '2026-09-23T00:00:00.000Z',
    );
    expect(body?['status'], 'Vehicle Condition Satisfactory');
    expect(body?['defects'], isEmpty);
  });

  test('missing driver or vehicle does not invent an id', () {
    expect(
      buildDvirCreateBody(
        driverId: 0,
        deviceId: 7,
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
        deviceId: 7,
        uniqueId: 'No Vehicle',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
      ),
      isNull,
    );
  });

  test('missing deviceId is refused — the server requires it (400 live)', () {
    expect(
      buildDvirCreateBody(
        driverId: 106,
        deviceId: null,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
      ),
      isNull,
    );
  });
}

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
    // العقد الحيّ لا يعرّف deviceId/uniqueId/signatureData في جسم الطلب.
    expect(body?.containsKey('deviceId'), isFalse);
    expect(body?.containsKey('signatureData'), isFalse);
    // الخادم يحل الجهاز من vehicle.uniqueId فقط (تجربة 200: "485" → 485؛
    // ومعرفنا النصي أعاد NPE) — فيُرسل الرقمي كسلسلة.
    expect(body?['vehicle']['uniqueId'], '7');
    // DVIR-09: عيوب على السلك تُصالح الحالة إلى Has Defects.
    expect(body?['status'], 'Has Defects');
    // التوقيع على السلك بصيغة data URL (العقد الحيّ الناجح 200) — المحلي
    // يبقى base64 مجردة في dvirSignatureData.
    expect(body?['signature'], 'data:image/png;base64,AQID');
    // العقد الحي: detects أسماء نصية — ملاحظة السائق المخصصة تُرسل نصًا.
    expect(body?['vehicle']['detects'], ['brake leak']);
    expect(body?['vehicleDefects'], ['brake leak']);
    expect(body?['trailerDefects'], ['light out']);
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
    expect(body?['vehicleDefects'], isEmpty);
    expect(body?['trailerDefects'], isEmpty);
    expect(body?.containsKey('defects'), isFalse);
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

  group('create body location follows the live object contract', () {
    test('free text is not sent as a location (the field is an object)', () {
      final body = buildDvirCreateBody(
        driverId: 106,
        deviceId: 7,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
        location: 'Riyadh, Exit 5 North',
      );
      expect(body?.containsKey('location'), isFalse);
      expect(body?.containsKey('latitude'), isFalse);
      expect(body?.containsKey('longitude'), isFalse);
    });

    test('a full coordinate pair is sent as a location object', () {
      final body = buildDvirCreateBody(
        driverId: 106,
        deviceId: 7,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
        location: '24.7136, 46.6753',
      );
      expect(body?['location'], {'latitude': 24.7136, 'longitude': 46.6753});
      expect(body?.containsKey('locationText'), isFalse);
      expect(body?.containsKey('latitude'), isFalse);
      expect(body?.containsKey('longitude'), isFalse);
    });

    test('GPS coordinates are sent in the live object shape', () {
      final body = buildDvirCreateBody(
        driverId: 101,
        deviceId: 503,
        uniqueId: 'ELD-PB-103',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-11-07T22:11:46.623Z',
        location: '21.2356, -86.7451',
      );
      expect(body?['location'], {'latitude': 21.2356, 'longitude': -86.7451});
      expect(body?['location'], isA<Map<String, double>>());
    });

    test('explicit numeric latitude and longitude produce location object directly', () {
      final body = buildDvirCreateBody(
        driverId: 101,
        deviceId: 503,
        uniqueId: 'ELD-PB-103',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-11-07T22:11:46.623Z',
        latitude: 21.2356,
        longitude: -86.7451,
        location: 'Dallas Terminal',
      );
      expect(body?['location'], {'latitude': 21.2356, 'longitude': -86.7451});
      expect(body?['location'], isA<Map<String, double>>());
    });

    test('a half-parsed pair sends no location and invents no coordinates', () {
      final body = buildDvirCreateBody(
        driverId: 106,
        deviceId: 7,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
        location: '24.7136, unknown',
      );
      expect(body?.containsKey('location'), isFalse);
      expect(body?.containsKey('latitude'), isFalse);
      expect(body?.containsKey('longitude'), isFalse);
    });

    test('blank location sends no location field at all', () {
      final body = buildDvirCreateBody(
        driverId: 106,
        deviceId: 7,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'AQID',
        inspectionTime: '2026-09-23T00:00:00.000Z',
        location: '   ',
      );
      expect(body?.containsKey('location'), isFalse);
      expect(body?.containsKey('latitude'), isFalse);
      expect(body?.containsKey('longitude'), isFalse);
    });
  });

  test('live vehicle defects send catalog itemCodes, not names', () {
    // قرار المالك: أكواد الكتالوج لا الأسماء — كود قصير ثابت لا ينفجر
    // فوق varchar(50) في eld_dvir_defects ولا يتضاعف باللغتين.
    final body = buildDvirCreateBody(
      driverId: 101,
      deviceId: 503,
      uniqueId: 'ELD-PB-103',
      status: 'Has Defects',
      signatureData: 'AQID',
      inspectionTime: '2026-11-07T22:11:46.623Z',
      trailerNumber: '55588',
      catalogDefects: const [
        {
          'itemCode': 'BRAKES_SERVICE',
          'itemName': 'Service Brakes (including trailer connections)',
          'category': '',
          'stage': 'OPEN',
          'safetyAffecting': false,
        },
        {
          'itemCode': 'PARKING_BRAKE',
          'itemName': 'Parking Brake',
          'category': '',
          'stage': 'OPEN',
          'safetyAffecting': false,
        },
        {
          'itemCode': 'STEERING',
          'itemName': 'Steering Mechanism',
          'category': '',
          'stage': 'OPEN',
          'safetyAffecting': false,
        },
        {
          'itemCode': 'TRAILER_BRAKES',
          'itemName': 'Brakes',
          'category': 'TRAILER',
          'stage': 'OPEN',
          'safetyAffecting': true,
        },
        {
          'itemCode': 'COUPLING',
          'itemName': 'Coupling Devices',
          'category': 'TRAILER',
          'stage': 'OPEN',
          'safetyAffecting': true,
        },
      ],
    );

    expect(body?['vehicle']['detects'], [
      'BRAKES_SERVICE',
      'PARKING_BRAKE',
      'STEERING',
    ]);
    expect(body?['trailers'][0]['trailerNumber'], '55588');
    expect(body?['trailers'][0]['detects'], ['TRAILER_BRAKES', 'COUPLING']);
    expect(body?['vehicleDefects'], [
      'BRAKES_SERVICE',
      'PARKING_BRAKE',
      'STEERING',
    ]);
    expect(body?['trailerDefects'], ['TRAILER_BRAKES', 'COUPLING']);
    // العقد الحيّ لا يحتوي حقل `defects` في الطلب.
    expect(body?.containsKey('defects'), isFalse);

    for (final detects in [
      body?['vehicle']['detects'] as List<dynamic>,
      body?['trailers'][0]['detects'] as List<dynamic>,
      body?['vehicleDefects'] as List<dynamic>,
      body?['trailerDefects'] as List<dynamic>,
    ]) {
      expect(detects, everyElement(isA<String>()));
    }
  });

  test('catalog defects send codes; text-only scope keeps its text', () {
    final body = buildDvirCreateBody(
      driverId: 106,
      deviceId: 7,
      uniqueId: 'TRUCK-1',
      status: 'Has Defects',
      signatureData: 'AQID',
      inspectionTime: '2026-09-23T00:00:00.000Z',
      trailerNumber: 'TR-1',
      trailerDefects: 'light out',
      catalogDefects: [
        {
          'itemCode': 'BRAKES_SERVICE',
          'itemName': 'Service brakes',
          'category': 'VEHICLE',
          'severity': 'HIGH',
          'stage': 'OPEN',
        },
      ],
    );
    // الخادم يتوقع List<String> في vehicle.detects و trailers[].detects
    // (400 حي: Jackson Cannot deserialize String from Object).
    expect(body?['vehicle']['detects'], ['BRAKES_SERVICE']);
    expect(body?['trailers'][0]['trailerNumber'], 'TR-1');
    // نطاق المقطورة بلا كتالوج: النص المشتق يبقى بديلاً شرعياً.
    expect(body?['trailers'][0]['detects'], ['light out']);
    // `defects` ليس حقلاً في عقد الطلب الحيّ — إرساله سبب 400.
    expect(body?.containsKey('defects'), isFalse);
  });

  test('bilingual catalog duplicates collapse to one name per itemCode', () {
    final body = buildDvirCreateBody(
      driverId: 101,
      deviceId: 503,
      uniqueId: 'ELD-PB-103',
      status: 'Has Defects',
      signatureData: 'AQID',
      inspectionTime: '2026-11-07T22:11:46.623Z',
      catalogDefects: const [
        {
          'itemCode': 'BRAKES_SERVICE',
          'itemName': 'Service Brakes (including trailer connections)',
          'category': '',
        },
        {
          'itemCode': 'BRAKES_SERVICE',
          'itemName': 'فرامل الخدمة والتوقف وتوصيلات المقطورة',
          'category': '',
        },
        {
          'itemCode': 'PARKING_BRAKE',
          'itemName': 'Parking Brake',
          'category': '',
        },
        {
          'itemCode': 'PARKING_BRAKE',
          'itemName': 'فرامل الوقوف والانتظار',
          'category': '',
        },
      ],
    );
    // عيب مختار مرة واحدة = سجل عيب واحد: بالأكواد يصبح الإدخالان (عربي/
    // إنجليزي لنفس الكود) سلسلتين متطابقتين تُسقطان بالإزالة العامة.
    expect(body?['vehicle']['detects'], ['BRAKES_SERVICE', 'PARKING_BRAKE']);
    expect(body?['vehicleDefects'], body?['vehicle']['detects']);
  });
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/change_status_provider.dart';
import 'package:golden_feather_eld/features/inspection/data/providers/inspection_repository_providers.dart';
import 'package:golden_feather_eld/features/inspection/data/services/fmcsa_eld_output_generator.dart';
import 'package:golden_feather_eld/features/inspection/domain/repositories/inspection_repository.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/dot_inspection_providers.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/inspection_provider.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/location_entity.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

/// P3 — الصدق النظامي: لا تصنيع في طبقة العرض، ولا وثيقة FMCSA بوقت غير
/// موثوق، ولا ادعاء موقع مزيف. هذه الاختبارات تفشل على الكود قبل الإصلاح.

class _Repo extends Mock implements InspectionRepository {}

DotInspectionEvent _event({
  required int seq,
  required String time,
  required double odo,
}) {
  return DotInspectionEvent(
    sequenceNumber: seq,
    timeEt: time,
    eventCode: 'D',
    eventType: '1',
    description: 'Driving',
    location: '31.95, 35.91',
    odometer: odo,
    engineHours: odo / 10,
    origin: 'A',
    notes: '',
    certificationEvent: false,
  );
}

DotInspectionLog _log(
  int driverId,
  DateTime date, {
  List<DotInspectionEvent> events = const [],
}) {
  return DotInspectionLog(
    driverId: DriverId(driverId),
    driverName: 'Ali Kareem',
    logDate: date,
    displayDate: '${date.year}-${date.month}-${date.day}',
    displayLocation: '31.95, 35.91',
    certified: false,
    certifiedAt: null,
    eldRegistrationId: 'REG-$driverId',
    eldIdentifier: 'ELD-$driverId',
    eldProvider: 'GF ELD',
    vehicleNumber: 'TRK-$driverId',
    uniqueId: 'U-$driverId',
    vin: 'VIN$driverId',
    startOdometerKm: 100,
    endOdometerKm: 200,
    totalDistanceKm: 100,
    engineHours: 10,
    trailers: 'None',
    shippingDocuments: 'None',
    carrierName: 'Carrier$driverId',
    usdotNumber: 'DOT$driverId',
    mainOfficeAddress: 'Main',
    homeTerminalAddress: 'Home',
    activeDataDiagnostics: const [],
    activeDeviceMalfunctions: const [],
    events: events,
    readOnly: false,
  );
}

DotInspectionCycleDay _day(int driverId, DateTime date) {
  return DotInspectionCycleDay(
    driverId: DriverId(driverId),
    driverName: 'Ali Kareem',
    logDate: date,
    displayDate: '${date.year}-${date.month}-${date.day}',
    displayLocation: '31.95, 35.91',
    certified: false,
    certifiedAt: null,
    eldRegistrationId: 'REG-$driverId',
    eldIdentifier: 'ELD-$driverId',
    eldProvider: 'GF ELD',
    vehicleNumber: 'TRK-$driverId',
    uniqueId: 'U-$driverId',
    vin: 'VIN$driverId',
    startOdometerKm: 100,
    endOdometerKm: 200,
    totalDistanceKm: 100,
    engineHours: 10,
    trailers: 'None',
    shippingDocuments: 'None',
    carrierName: 'Carrier$driverId',
    usdotNumber: 'DOT$driverId',
    mainOfficeAddress: 'Main',
    homeTerminalAddress: 'Home',
    activeDataDiagnostics: const [],
    activeDeviceMalfunctions: const [],
    exemptDriver: false,
    hasUnidentifiedDriving: false,
    unidentifiedDrivingCount: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const DriverId(0));
    registerFallbackValue(DateTime(2026));
  });

  group('InspectionNotifier — لا تصنيع عند الفشل (P3)', () {
    test('offline with no cache fails honestly instead of inventing 8 days',
        () async {
      final repo = _Repo();
      when(() => repo.getCycle(driverId: const DriverId(7), days: 8))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      when(() => repo.getLogs(driverId: const DriverId(7)))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final notifier = InspectionNotifier(
        repository: repo,
        driverId: 7,
        loc: lookupAppLocalizations(const Locale('en')),
      );
      addTearDown(notifier.dispose);

      await notifier.startInspection();

      expect(notifier.state.isInspectionMode, isFalse,
          reason: 'a fabricated lock is worse than an honest error');
      expect(notifier.state.cycle, isEmpty,
          reason: 'no invented cycle days may reach the driver');
      expect(notifier.state.log, isNull,
          reason: 'no synthesized log may reach the inspector');
      expect(notifier.state.error, isNotNull);
    });

    test('cycle answered but the day log is missing keeps the start screen',
        () async {
      final repo = _Repo();
      final date = DateTime.utc(2026, 3, 15);
      when(() => repo.getCycle(driverId: const DriverId(7), days: 8))
          .thenAnswer((_) async => Right([_day(7, date)]));
      when(() => repo.getLogs(
            driverId: const DriverId(7),
            date: any(named: 'date'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));

      final notifier = InspectionNotifier(
        repository: repo,
        driverId: 7,
        loc: lookupAppLocalizations(const Locale('en')),
      );
      addTearDown(notifier.dispose);

      await notifier.startInspection();

      expect(notifier.state.isInspectionMode, isFalse,
          reason: 'Invariant E: no blind lock without displayable data');
      expect(notifier.state.error, isNotNull);
    });

    test('offline with real cached cycle and log still starts normally',
        () async {
      final repo = _Repo();
      final date = DateTime.utc(2026, 3, 15);
      when(() => repo.getCycle(driverId: const DriverId(7), days: 8))
          .thenAnswer((_) async => Right([_day(7, date)]));
      when(() => repo.getLogs(
            driverId: const DriverId(7),
            date: any(named: 'date'),
          )).thenAnswer((_) async => Right(_log(7, date)));
      when(() => repo.registerInspectionStart(
            driverId: any(named: 'driverId'),
          )).thenAnswer((_) async => const Right(unit));

      final notifier = InspectionNotifier(
        repository: repo,
        driverId: 7,
        loc: lookupAppLocalizations(const Locale('en')),
      );
      addTearDown(notifier.dispose);

      await notifier.startInspection();

      expect(notifier.state.isInspectionMode, isTrue,
          reason: 'SRS 6.8: roadside inspection must keep working offline');
      expect(notifier.state.cycle, hasLength(1));
      expect(notifier.state.log!.driverId.value, 7);
    });
  });

  group('dotInspection providers — لا شاشة/دورة مخترعة (P3)', () {
    test('screen provider surfaces the failure instead of a fake screen',
        () async {
      final repo = _Repo();
      when(() => repo.getScreen())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final container = ProviderContainer(overrides: [
        inspectionRepositoryProvider.overrideWithValue(repo),
        currentDriverIdProvider.overrideWithValue(7),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(dotInspectionScreenProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('cycle provider surfaces the failure instead of inventing 8 days',
        () async {
      final repo = _Repo();
      when(() => repo.getCycle(
            driverId: any(named: 'driverId'),
            days: any(named: 'days'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = ProviderContainer(overrides: [
        inspectionRepositoryProvider.overrideWithValue(repo),
        currentDriverIdProvider.overrideWithValue(7),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(dotInspectionCycleProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('gpsLocationText — لا موقع مزيف (P3)', () {
    test('empty for null and zero coordinates; real text otherwise', () {
      expect(gpsLocationText(null), isEmpty);
      expect(
        gpsLocationText(LocationEntity(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime(2026, 3, 15),
        )),
        isEmpty,
        reason: 'the (0,0) default without a real fix is not a location',
      );
      expect(
        gpsLocationText(LocationEntity(
          latitude: 31.95,
          longitude: 35.91,
          timestamp: DateTime(2026, 3, 15),
        )),
        '31.95, 35.91',
      );
    });
  });

  group('FmcsaEldOutputGenerator — وقت موثوق وتواريخ حقيقية (P3)', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    late Directory docsDir;

    setUp(() {
      docsDir = Directory.systemTemp.createTempSync('fmcsa_p3');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return docsDir.path;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
    });

    test(
        'file header uses the trusted creation time and each event carries '
        'its own log date', () async {
      final day14 = DateTime.utc(2026, 3, 14);
      final day15 = DateTime.utc(2026, 3, 15);

      final path = await FmcsaEldOutputGenerator.generateAndSave(
        logs: {
          '7:day14': _log(7, day14, events: [
            _event(seq: 1, time: '08:00 AM', odo: 100),
          ]),
          '7:day15': _log(7, day15, events: [
            _event(seq: 2, time: '09:30 AM', odo: 150),
          ]),
        },
        outputFileComment: 'roadside',
        fileCreationUtc: DateTime.utc(2026, 3, 15, 14, 30, 5),
      );

      final lines = File(path).readAsStringSync().split('\n');
      final header = lines.firstWhere((l) => l.startsWith('1,'));
      expect(header, contains(',031526,143005,'),
          reason: 'the legal artifact must be stamped with trusted time, '
              'not the device wall clock');

      final records = lines.where((l) => l.startsWith('5,')).toList();
      expect(records, hasLength(2));
      expect(records[0].split(',')[5], '031426',
          reason: 'the 03-14 event must carry its own date, not the file date');
      expect(records[1].split(',')[5], '031526');
      expect(records[0].split(',')[6], '080000');
      expect(records[1].split(',')[6], '093000');
    });
  });
}

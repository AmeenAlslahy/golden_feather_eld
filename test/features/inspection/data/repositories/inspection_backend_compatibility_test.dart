import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_inspection_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/inspection/data/repositories/inspection_repository_impl.dart';
import 'package:golden_feather_eld/features/inspection/domain/inspection_transfer.dart';
import 'package:mocktail/mocktail.dart';

// ============================================================================
// EC-0.2a production-readiness: adapter + repository compatibility.
//
// Unlike the earlier suites, this one does NOT stub `InspectionBackend`.
// It drives the REAL `EldInspectionBackend` + `DotInspectionMapper` with
// response bodies shaped exactly like the documented contract, then feeds the
// result into the corrected repository.
//
// Body provenance:
//   * screenLiveBody  — transcribed from
//     test/backend/live_contract_2026_09_25_test.dart:146-166, which the file
//     header documents as "the actual bodies the live server returned on
//     2026-09-25 (driver 106, ELD-PRO-1006)".
//   * CYCLE_BODY / LOG_BODY — shaped from openapi.yaml schemas
//     (InspectionLogDisplayResponse declares `driver -> DriverResponse`;
//     the cycle array schema declares no `driver`). No live body was recorded
//     for these two endpoints, so the presence of `driver` there remains
//     UNKNOWN and is exercised parametrically below.
// ============================================================================

class _MockApiClient extends Mock implements ApiClient {}

class _ToggleNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  bool get isConnected => connected;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

T? rightOf<T>(Either<Failure, T> either) => either.fold((_) => null, (v) => v);

Failure leftOf<T>(Either<Failure, T> either) =>
    either.fold((f) => f, (_) => throw StateError('expected a Left result'));

// --- bodies ---------------------------------------------------------------

/// Recorded live screen body (driver 106) — see provenance note above.
final Map<String, dynamic> screenLiveBody = {
  'screenTitle': 'DOT Inspection',
  'guidanceText': 'Hand the device to the inspector.',
  'handOverDeviceNotice': 'Read-only while inspection is active.',
  'carrierComplianceStatement': 'Compliant with 49 CFR 395',
  'carrierName': 'Golden Feather Carriers',
  'usdotNumber': '1234567',
  'eldIdentifier': 'ELD-PRO-1006',
  'eldRegistrationId': 'REG-1',
  'driver': {'id': 106, 'name': 'Driver Ahmed'},
  'inspectionDate': '2026-09-25',
  'cycleDaysCovered': 8,
  'canStartInspection': true,
  'canSendLogs': true,
  'canEmailLogs': true,
  'canViewInformationPacket': true,
  'inspectionActive': false,
  'activeInspectionId': null,
  'readOnlyMode': false,
  'inspectorName': null,
};

Map<String, dynamic> logBody({
  required int? driverId,
  bool omitOptional = false,
  bool omitRequired = false,
}) =>
    {
      if (driverId != null) 'driver': {'id': driverId, 'name': 'Driver Ahmed'},
      'logDate': '2026-09-25',
      'displayDate': '2026-09-25',
      'displayLocation': 'Riyadh, KSA',
      'certified': true,
      'certifiedAt': '2026-09-25T20:00:00Z',
      if (!omitRequired) ...{
        'eldRegistrationId': 'REG-1',
        'eldIdentifier': 'ELD-PRO-1006',
        'vehicleNumber': 'TRK-1006',
        'vin': '1FTFW1E50MFA10006',
        'usdotNumber': '1234567',
        'carrierName': 'Golden Feather Carriers',
        'driverName': 'Driver Ahmed',
      },
      if (!omitOptional) ...{
        'eldProvider': 'ELD-PROVIDER',
        'startOdometerKm': 100.0,
        'endOdometerKm': 180.0,
        'totalDistanceKm': 80.0,
        'engineHours': 3.5,
        'trailers': '',
        'shippingDocuments': '',
        'mainOfficeAddress': 'Riyadh',
        'homeTerminalAddress': 'Jeddah',
        'activeDataDiagnostics': <String>[],
        'activeDeviceMalfunctions': <String>[],
        'events': <Map<String, dynamic>>[],
        'readOnly': false,
        'driverLicenseNumber': 'DL-987654',
        'driverLicenseState': 'SA',
      },
    };

Map<String, dynamic> cycleDayBody({
  required int? driverId,
  bool omitRequired = false,
}) =>
    {
      if (driverId != null) 'driver': {'id': driverId, 'name': 'Driver Ahmed'},
      'logDate': '2026-09-25',
      'displayDate': '2026-09-25',
      'displayLocation': 'Riyadh, KSA',
      'certified': true,
      'certifiedAt': '2026-09-25T20:00:00Z',
      if (!omitRequired) ...{
        'eldRegistrationId': 'REG-1',
        'eldIdentifier': 'ELD-PRO-1006',
        'vehicleNumber': 'TRK-1006',
        'vin': '1FTFW1E50MFA10006',
        'usdotNumber': '1234567',
        'carrierName': 'Golden Feather Carriers',
        'driverName': 'Driver Ahmed',
      },
      'eldProvider': 'ELD-PROVIDER',
      'startOdometerKm': 100.0,
      'endOdometerKm': 180.0,
      'totalDistanceKm': 80.0,
      'engineHours': 3.5,
      'trailers': '',
      'shippingDocuments': '',
      'mainOfficeAddress': 'Riyadh',
      'homeTerminalAddress': 'Jeddah',
      'activeDataDiagnostics': <String>[],
      'activeDeviceMalfunctions': <String>[],
      'exemptDriver': false,
      'hasUnidentifiedDriving': false,
      'unidentifiedDrivingCount': 0,
    };

// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(const DriverId(1));

  const driver = DriverId(106); // the live account used in the recordings
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory docsDir;
  late _MockApiClient api;
  late _ToggleNetworkInfo network;
  late InspectionRepositoryImpl repo;

  Map<String, dynamic>? screenBody;
  Map<String, dynamic>? logResp;
  List<dynamic>? cycleResp;
  bool backendDown = false;

  void stubApi() {
    api = _MockApiClient();
    api = _MockApiClient();
    when(() => api.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        )).thenAnswer((inv) async {
      if (backendDown) return err(const NetworkError(code: 'offline', l10nKey: 'offline'));
      final p = inv.positionalArguments[0] as String;
      if (p == '/eld/dot-inspection') {
        return ok(ApiResponse<Map<String, dynamic>>(
            statusCode: 200, isSuccess: true, data: screenBody ?? const {}));
      }
      return ok(ApiResponse<Map<String, dynamic>>(
          statusCode: 200, isSuccess: true, data: logResp ?? const {}));
    });
    when(() => api.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        )).thenAnswer((inv) async {
      if (backendDown) return err(const NetworkError(code: 'offline', l10nKey: 'offline'));
      return ok(ApiResponse<List<dynamic>>(
          statusCode: 200, isSuccess: true, data: cycleResp ?? const []));
    });
  }

  setUp(() {
    SessionEpoch.resetForTests();
    docsDir = Directory.systemTemp.createTempSync('compat_docs');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (c) async =>
            c.method == 'getApplicationDocumentsDirectory' ? docsDir.path : null);
    screenBody = Map<String, dynamic>.from(screenLiveBody);
    logResp = logBody(driverId: driver.value);
    cycleResp = [cycleDayBody(driverId: driver.value)];
    backendDown = false;
    network = _ToggleNetworkInfo();
    stubApi();
    repo = InspectionRepositoryImpl(EldInspectionBackend(api), network);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
    SessionEpoch.resetForTests();
  });

  Future<Either<Failure, TransferOutcome>> goOfflineAndSend() async {
    backendDown = true;
    network.connected = false;
    return repo.sendLogs(
      driverId: driver,
      method: TransferMethod.usb,
      comment: 'roadside check',
    );
  }

  // ==========================================================================
  // C1 — complete, contract-shaped, live-recorded response is ACCEPTED
  // ==========================================================================
  test('C1: a complete contract-shaped response is accepted end to end',
      () async {
    final screen = await repo.getScreen(driverId: driver);
    expect(screen.isRight(), isTrue);
    expect(rightOf(screen)!.driverId.value, 106);
    expect(rightOf(screen)!.driverName, 'Driver Ahmed');

    final cycle = await repo.getCycle(driverId: driver, days: 8);
    expect(cycle.isRight(), isTrue);

    final log = await repo.getLogs(driverId: driver);
    expect(log.isRight(), isTrue);
    expect(rightOf(log)!.driverId.value, 106);

    // Offline FMCSA generation must succeed and name the driver.
    final outcome = await goOfflineAndSend();
    expect(outcome.isRight(), isTrue,
        reason: 'complete verified data must still generate: ${leftOfOrNull(outcome)}');

    final path = rightOf(outcome)!.text.substring('OFFLINE_GENERATED:'.length);
    final header =
        File(path).readAsLinesSync().firstWhere((l) => l.startsWith('1,'));
    expect(header.contains('106'), isTrue, reason: header);
  });

  // ==========================================================================
  // C2 — driver.id absent  ⇒  owner unknown  ⇒  accepted, never "verified"
  // ==========================================================================
  test('C2: a response without driver.id is accepted but never verified',
      () async {
    logResp = logBody(driverId: null); // contract: `driver` is not required
    final log = await repo.getLogs(driverId: driver);
    expect(log.isRight(), isTrue, reason: 'absence is not a mismatch');
    expect(rightOf(log)!.driverId.value, 0);

    // It must not reach a regulatory file.
    final outcome = await goOfflineAndSend();
    expect(outcome.isLeft(), isTrue,
        reason: 'unknown ownership must not produce an ELD file');
  });

  // ==========================================================================
  // C3 — driver.id = 0 behaves exactly like absent
  // ==========================================================================
  test('C3: driver.id = 0 is treated as unknown, not as driver zero',
      () async {
    logResp = logBody(driverId: 0);
    final log = await repo.getLogs(driverId: driver);
    expect(log.isRight(), isTrue);

    final outcome = await goOfflineAndSend();
    expect(outcome.isLeft(), isTrue);
  });

  // ==========================================================================
  // C4 — mismatching driver.id is REJECTED
  // ==========================================================================
  test('C4: a response for a different driver is rejected', () async {
    logResp = logBody(driverId: 999);
    final log = await repo.getLogs(driverId: driver);
    expect(log.isLeft(), isTrue);
    expect(leftOf(log).message, 'inspectionOwnerMismatch');
  });

  // ==========================================================================
  // C5 — missing OPTIONAL fields is still a valid response
  // ==========================================================================
  test('C5: missing optional fields does not block the workflow', () async {
    logResp = logBody(driverId: driver.value, omitOptional: true);
    final log = await repo.getLogs(driverId: driver);
    expect(log.isRight(), isTrue);
    expect(rightOf(log)!.driverId.value, 106);

    final outcome = await goOfflineAndSend();
    expect(outcome.isRight(), isTrue,
        reason: 'optional blanks must not reject a legitimate file');
  });

  // ==========================================================================
  // C6 — missing REQUIRED identity fields ⇒ refuse, and leave no artifact
  // ==========================================================================
  test('C6: missing required identity fields refuse and delete the file',
      () async {
    logResp = logBody(driverId: driver.value, omitRequired: true);
    expect((await repo.getLogs(driverId: driver)).isRight(), isTrue);

    final before = docsDir.listSync().length;
    final outcome = await goOfflineAndSend();

    expect(outcome.isLeft(), isTrue);
    expect(leftOf(outcome).message, 'inspectionIncompleteOutput');
    expect(docsDir.listSync().length, before,
        reason: 'an invalid CSV must not be left on disk');
  });

  // ==========================================================================
  // C7 — cycle WITHOUT driver.id (the schema gap) must not break the screen
  // ==========================================================================
  test('C7: a cycle response without driver.id does not block other reads',
      () async {
    cycleResp = [cycleDayBody(driverId: null)];

    final screen = await repo.getScreen(driverId: driver);
    expect(screen.isRight(), isTrue, reason: 'screen has its own driver.id');

    final log = await repo.getLogs(driverId: driver);
    expect(log.isRight(), isTrue, reason: 'log has its own driver.id');

    // The cycle is accepted (no mismatch) but is not "verified".
    final cycle = await repo.getCycle(driverId: driver, days: 8);
    expect(cycle.isRight(), isTrue);
    expect(rightOf(cycle)!.first.driverId.value, 0);

    // Screen + log are verified ⇒ the file is still produced.
    final outcome = await goOfflineAndSend();
    expect(outcome.isRight(), isTrue);
    final path = rightOf(outcome)!.text.substring('OFFLINE_GENERATED:'.length);
    final header =
        File(path).readAsLinesSync().firstWhere((l) => l.startsWith('1,'));
    expect(header.contains('106'), isTrue, reason: header);
  });

  // ==========================================================================
  // C8 — CSV quoting: a comma inside a quoted field shifts naive indices
  // ==========================================================================
  test('C8: a comma inside CarrierName breaks the post-generation validator',
        () async {
    // Legitimate-looking carrier name that contains a comma.
    screenBody = Map<String, dynamic>.from(screenLiveBody)
      ..['carrierName'] = 'Smith, John Transport';

    expect((await repo.getScreen(driverId: driver)).isRight(), isTrue);
    expect((await repo.getLogs(driverId: driver)).isRight(), isTrue);

    final outcome = await goOfflineAndSend();
    final file = rightOf(outcome);
    if (file == null) {
      // Rejected outright — safe outcome, but the validator is not quote-aware.
      expect(leftOf(outcome).message, 'inspectionIncompleteOutput');
      debugPrint('C8 outcome = REJECTED (${leftOf(outcome).message})');
      return;
    }
    // Accepted. Document exactly what the naive index-based validator saw.
    final path = file.text.substring('OFFLINE_GENERATED:'.length);
    final header =
        File(path).readAsLinesSync().firstWhere((l) => l.startsWith('1,'));
    final naive = header.split(',');
    debugPrint('C8 outcome = ACCEPTED');
    debugPrint('C8 raw header   : $header');
    debugPrint('C8 naive[6]     : "${naive[6]}"   (expected USDOTNumber)');
    debugPrint('C8 naive[9]     : "${naive[9]}"   (expected DriverID=106)');
    expect(naive[9], isNot('106'),
        reason: 'documented defect: index-based validation is not quote aware');
  });
}

String? leftOfOrNull(Either<Failure, TransferOutcome> e) {
  if (e.isRight()) return null;
  return e.fold((f) => f.message, (_) => null);
}

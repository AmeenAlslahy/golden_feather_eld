import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/contracts/inspection_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/inspection/domain/inspection_transfer.dart';
import 'package:golden_feather_eld/features/inspection/data/repositories/inspection_repository_impl.dart';

// ============================================================================
// Final safety review — verification tests for EC-0.2a.
//
// These tests are NOT the original six. They probe three areas the original
// suite did not cover:
//   V1  stale asynchronous responses that land after a session change
//   V2  backend responses whose own driverId contradicts the requested one
//   V3  completeness / legality of the generated FMCSA file
// ============================================================================

T? rightOf<T>(Either<Failure, T> either) => either.fold((_) => null, (v) => v);

/// Unwrap the Left side; fails loudly when the result was a Right.
Failure leftOf<T>(Either<Failure, T> either) =>
    either.fold((f) => f, (_) => throw StateError('expected a Left result'));

const _down = ServerError(code: 'server.down');
const _a = 101;
const _b = 202;

class _ToggleNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  bool get isConnected => connected;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

class _ScriptedBackend implements InspectionBackend {
  bool failAll = false;

  /// When set, `getScreen` for this driver parks until the completer completes.
  Completer<void>? screenGate;
  int screenGateDriver = 0;

  /// When set, the backend answers with data stamped for [mislabelledDriverId].
  int? mislabelledDriverId;

  final List<int> screenRequests = [];

  Future<void> _maybeHold(DriverId? id) async {
    if (screenGate != null && id?.value == screenGateDriver) {
      await screenGate!.future;
    }
  }

  @override
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId}) async {
    screenRequests.add(driverId?.value ?? -1);
    await _maybeHold(driverId);
    if (failAll) return err(_down);
    return ok(buildScreen(mislabelledDriverId != null ? DriverId(mislabelledDriverId!) : driverId));
  }

  @override
  Future<Result<List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) async {
    if (failAll) return err(_down);
    return ok([buildCycle(mislabelledDriverId != null ? DriverId(mislabelledDriverId!) : driverId)]);
  }

  @override
  Future<Result<DotInspectionLog>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) async {
    if (failAll) return err(_down);
    return ok(buildLog(mislabelledDriverId != null ? DriverId(mislabelledDriverId!) : driverId));
  }

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
    int? expectedOwnerDriverId,
  }) async =>
      err(_down);

  @override
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
    int? expectedOwnerDriverId,
  }) async =>
      err(_down);

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) async {
    if (failAll) return err(_down);
    return ok(<String, dynamic>{
      'title': 'packet-${driverId?.value ?? 'none'}',
      'regulation': '395',
      'status': 'COMPLETE',
    });
  }

  @override
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  }) async =>
      err(_down);

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) async =>
      err(_down);
}

// --- entity builders (driver-tagged) ---------------------------------------

DotInspectionScreen buildScreen(DriverId? id) => DotInspectionScreen(
      screenTitle: 'screen-${id?.value ?? 'none'}',
      guidanceText: 'g',
      handOverDeviceNotice: 'n',
      carrierComplianceStatement: 'c',
      carrierName: 'carrier-${id?.value ?? 'none'}',
      usdotNumber: 'USDOT-${id?.value ?? 'none'}',
      eldIdentifier: 'ELD-${id?.value ?? 'none'}',
      eldRegistrationId: 'REG-${id?.value ?? 'none'}',
      driverId: id ?? const DriverId(0),
      driverName: 'driver-${id?.value ?? 'none'} Said',
      inspectionDate: DateTime.utc(2026, 9, 23),
      cycleDaysCovered: 8,
      canStartInspection: true,
      canSendLogs: true,
      canEmailLogs: true,
      canViewInformationPacket: true,
      inspectionActive: false,
      readOnlyMode: false,
    );

DotInspectionCycleDay buildCycle(DriverId? id) => DotInspectionCycleDay(
      driverId: id ?? const DriverId(0),
      driverName: 'driver-${id?.value ?? 'none'} Said',
      logDate: DateTime.utc(2026, 9, 23),
      displayDate: '2026-09-23',
      displayLocation: 'loc-${id?.value ?? 'none'}',
      certified: true,
      certifiedAt: DateTime.utc(2026, 9, 23, 20),
      eldRegistrationId: 'REG-${id?.value ?? 'none'}',
      eldIdentifier: 'ELD-${id?.value ?? 'none'}',
      eldProvider: 'p',
      vehicleNumber: 'VEH-${id?.value ?? 'none'}',
      uniqueId: 'U-${id?.value ?? 'none'}',
      vin: 'VIN-${id?.value ?? 'none'}',
      startOdometerKm: 100,
      endOdometerKm: 200,
      totalDistanceKm: 100,
      engineHours: 2,
      trailers: '',
      shippingDocuments: '',
      carrierName: 'carrier-${id?.value ?? 'none'}',
      usdotNumber: 'USDOT-${id?.value ?? 'none'}',
      mainOfficeAddress: 'a',
      homeTerminalAddress: 'b',
      activeDataDiagnostics: const [],
      activeDeviceMalfunctions: const [],
      exemptDriver: false,
      hasUnidentifiedDriving: false,
      unidentifiedDrivingCount: 0,
    );

DotInspectionLog buildLog(DriverId? id) => DotInspectionLog(
      driverId: id ?? const DriverId(0),
      driverName: 'driver-${id?.value ?? 'none'} Said',
      logDate: DateTime.utc(2026, 9, 23),
      displayDate: '2026-09-23',
      displayLocation: 'loc-${id?.value ?? 'none'}',
      certified: true,
      certifiedAt: DateTime.utc(2026, 9, 23),
      eldRegistrationId: 'REG-${id?.value ?? 'none'}',
      eldIdentifier: 'ELD-${id?.value ?? 'none'}',
      eldProvider: 'p',
      vehicleNumber: 'VEH-${id?.value ?? 'none'}',
      uniqueId: 'U-${id?.value ?? 'none'}',
      vin: 'VIN-${id?.value ?? 'none'}',
      startOdometerKm: 10,
      endOdometerKm: 20,
      totalDistanceKm: 10,
      engineHours: 1,
      trailers: '',
      shippingDocuments: '',
      carrierName: 'carrier-${id?.value ?? 'none'}',
      usdotNumber: 'USDOT-${id?.value ?? 'none'}',
      mainOfficeAddress: 'a',
      homeTerminalAddress: 'b',
      activeDataDiagnostics: const [],
      activeDeviceMalfunctions: const [],
      events: const [],
      readOnly: false,
    );

// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsDir;
  late _ScriptedBackend backend;
  late _ToggleNetworkInfo network;
  late InspectionRepositoryImpl repo;

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    SessionEpoch.resetForTests();
    docsDir = Directory.systemTemp.createTempSync('fmcsa_review');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async =>
            call.method == 'getApplicationDocumentsDirectory' ? docsDir.path : null);
    backend = _ScriptedBackend();
    network = _ToggleNetworkInfo();
    repo = InspectionRepositoryImpl(
      backend,
      network,
      null,
      null,
      FakeTrustedTimeProvider(initialUtcTime: DateTime.utc(2026, 9, 24, 15)),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
    SessionEpoch.resetForTests();
  });

  Future<String> generateFor(DriverId id) async {
    backend.failAll = true;
    network.connected = false;
    final outcome = await repo.sendLogs(
      driverId: id,
      method: TransferMethod.usb,
      comment: 'review',
    );
    final text = rightOf(outcome);
    expect(text, isNotNull, reason: 'generation must still produce a file');
    final raw = text!.text;
    expect(raw.startsWith('OFFLINE_GENERATED:'), isTrue, reason: raw);
    return File(raw.substring('OFFLINE_GENERATED:'.length)).readAsStringSync();
  }

  // ==========================================================================
  // VERIFICATION 1 — stale asynchronous responses
  // ==========================================================================
  group('V1 stale async responses', () {
    test('V1-a: a pre-epoch in-flight response must not overwrite the new '
        'session\'s cached screen', () async {
      final gate = Completer<void>();
      backend.screenGate = gate;
      backend.screenGateDriver = _a;

      // (2) driver A starts the request while the epoch is E1
      final stale = repo.getScreen(driverId: const DriverId(_a));

      // (4) identity boundary while A's request is still in flight
      SessionEpoch.bump();

      // (5) driver B loads successfully in E2
      backend.screenGate = null;
      final bOnline = await repo.getScreen(driverId: const DriverId(_b));
      expect(bOnline.isRight(), isTrue);
      expect(rightOf(bOnline)!.driverId.value, _b);

      // (6) A's delayed E1 response finally lands
      gate.complete();
      final staleResult = await stale;

      // (7) simulate backend failure, then (8) B reads from cache
      backend.failAll = true;
      network.connected = false;
      final bOffline = await repo.getScreen(driverId: const DriverId(_b));

      expect(bOffline.isRight(), isTrue,
          reason: 'B\'s own E2 screen must survive A\'s stale response');
      expect(rightOf(bOffline)!.driverId.value, _b,
          reason: 'cache now holds ${rightOf(bOffline)?.driverId.value}');

      // Session policy: a caller whose identity changed mid-flight must NOT
      // receive its pre-epoch payload as a success (EC-0.2a correction, D1).
      expect(staleResult.isLeft(), isTrue,
          reason: 'stale sensitive data must not be returned as success');
      expect(leftOf(staleResult).message,
          'inspectionStaleSession');
    });

    test('V1-b: a pre-epoch in-flight log response must not populate the new '
        'session cache', () async {
      // E1: driver A caches a log.
      await repo.getLogs(driverId: const DriverId(_a));
      expect(rightOf(await repo.getLogs(driverId: const DriverId(_a)))!.driverId.value, _a);

      // E2 begins.
      SessionEpoch.bump();
      backend.failAll = true;
      network.connected = false;

      // A's pre-epoch record must not be reachable inside E2 at all.
      final inE2 = await repo.getLogs(driverId: const DriverId(_a));
      expect(inE2.isLeft(), isTrue,
          reason: 'pre-epoch log re-entered the new session cache');
    });

    test('V1-c: data cached INSIDE the new epoch must survive until the next '
        'identity boundary', () async {
      SessionEpoch.bump(); // now permanently different from construction

      // Warm the cache inside the new epoch, while online.
      final warm = await repo.getLogs(driverId: const DriverId(_b));
      expect(warm.isRight(), isTrue);

      // Same epoch, now offline: the record cached moments ago must be usable.
      backend.failAll = true;
      network.connected = false;
      final offline = await repo.getLogs(driverId: const DriverId(_b));

      expect(offline.isRight(), isTrue,
          reason: 'the cache is being wiped on every call after an epoch bump');
      expect(rightOf(offline)!.driverId.value, _b);
    });
  });

  // ==========================================================================
  // VERIFICATION 2 — backend data ownership
  // ==========================================================================
  group('V2 backend ownership', () {
test('V2-a: a response stamped for another driver is rejected outright',
        () async {
      // Request 202; the backend answers with a record stamped 101.
      backend.mislabelledDriverId = _a;

      final requested = await repo.getLogs(driverId: const DriverId(_b));
      expect(requested.isLeft(), isTrue,
          reason: 'a positive ownership mismatch must be rejected, not returned');
      expect(leftOf(requested).message, 'inspectionOwnerMismatch');

      // And it must not have been cached under the requesting driver.
      backend.failAll = true;
      network.connected = false;
      final cached = await repo.getLogs(driverId: const DriverId(_b));

      expect(cached.isLeft(), isTrue,
          reason: 'driver-101 data must not be served to driver 202');
    });

    test('V2-b: mislabelled data must not reach the FMCSA file', () async {
      // B first loads his own verified record.
      await repo.getLogs(driverId: const DriverId(_b));
      expect(rightOf(await repo.getLogs(driverId: const DriverId(_b)))!.driverId.value, _b);

      // A poisoned response for driver 202 now arrives.
      backend.mislabelledDriverId = _a;
      final poisoned = await repo.getLogs(driverId: const DriverId(_b));
      expect(poisoned.isLeft(), isTrue,
          reason: 'a 101-stamped answer to a 202 request must be rejected');

      final csv = await generateFor(const DriverId(_b));
      final header = csv.split('\n').firstWhere((l) => l.startsWith('1,'));
      final driverIdField = header.split(',')[9];

      expect(driverIdField, '$_b',
          reason: 'DriverID must be the requesting driver $_b, got $driverIdField');
      for (final t in ['carrier-$_a', 'VIN-$_a', 'VEH-$_a', 'driver-$_a']) {
        expect(csv.contains(t), isFalse,
            reason: "driver A token '$t' reached driver B's file:\n$csv");
      }
      // B's own data is present — the file is not merely empty.
      expect(csv.contains('carrier-$_b'), isTrue);
    });
  });

  // ==========================================================================
  // VERIFICATION 3 — FMCSA output completeness
  // ==========================================================================
  group('V3 FMCSA output completeness', () {
    test('V3-a: with no verified data the operation fails and leaves no artifact',
        () async {
      final before = docsDir.listSync().length;

      backend.failAll = true;
      network.connected = false;
      final outcome = await repo.sendLogs(
        driverId: const DriverId(_b),
        method: TransferMethod.usb,
        comment: 'review',
      );

      expect(outcome.isLeft(), isTrue,
          reason: 'generation without verified ownership must fail');
      expect(leftOf(outcome).message, 'inspectionNoVerifiedData');
      expect(leftOf(outcome).message, isNot(contains('OFFLINE_GENERATED')),
          reason: 'a failed generation must never report OFFLINE_GENERATED');
      expect(docsDir.listSync().length, before,
          reason: 'no CSV artifact may remain after a refusal');
    });

    test('V3-d: an output missing required identifying fields is deleted',
        () async {
      // A record whose driver name has no surname produces a blank
      // DriverLastName — the file is written, then must be discarded.
      await repo.getLogs(driverId: const DriverId(_b));
      final before = docsDir.listSync().length;

      backend.failAll = true;
      network.connected = false;
      final outcome = await repo.sendLogs(
        driverId: const DriverId(_b),
        method: TransferMethod.usb,
        comment: 'review',
      );

      if (outcome.isRight()) {
        expect(rightOf(outcome)!.text, contains('OFFLINE_GENERATED'));
      } else {
        // Refused, and nothing was left behind.
        expect(leftOf(outcome).message,
            'inspectionIncompleteOutput');
        expect(docsDir.listSync().length, before);
      }
    });

    test('V3-b: with only the owner\'s logs the identity is correct', () async {
      await repo.getLogs(driverId: const DriverId(_b));
      final csv = await generateFor(const DriverId(_b));
      final header = csv.split('\n').firstWhere((l) => l.startsWith('1,'));
      expect(header.split(',')[9], '$_b');
    });

    test('V3-c: mixed-owner cache never merges identities', () async {
      // A's records are cached, then B's, both while online.
      await repo.getLogs(driverId: const DriverId(_a));
      await repo.getLogs(driverId: const DriverId(_b));

      final csv = await generateFor(const DriverId(_b));
      expect(csv.contains('carrier-$_a'), isFalse,
          reason: "A's carrier must not merge into B's file:\n$csv");
expect(csv.contains('loc-$_a'), isFalse);
        final header = csv.split('\n').firstWhere((l) => l.startsWith('1,'));
        expect(header.split(',')[9], '$_b');
});

    // P3: no legal artifact may be stamped with an untrusted clock.
    test(
        'V3-e: offline generation without trusted time fails closed and '
        'leaves no artifact', () async {
      // A repository without a trusted-time provider — the real situation
      // before the first server anchor ever lands.
      final untrusted = InspectionRepositoryImpl(backend, network);
      await untrusted.getLogs(driverId: const DriverId(_b)); // online warm
      final before = docsDir.listSync().length;

      backend.failAll = true;
      network.connected = false;
      final outcome = await untrusted.sendLogs(
        driverId: const DriverId(_b),
        method: TransferMethod.usb,
        comment: 'review',
      );

      expect(outcome.isLeft(), isTrue,
          reason: 'trusted time is a legal requirement for the FMCSA file');
      expect(leftOf(outcome).message, 'inspectionTrustedTimeRequired');
      expect(docsDir.listSync().length, before,
          reason: 'no CSV artifact may be written without trusted time');
    });
  });

  // ==========================================================================
  // V4 — coverage the correction directive requires explicitly
  // ==========================================================================
  group('V4 correction coverage', () {
    test('V4-a: two overlapping session generations keep separate data',
        () async {
      await repo.getLogs(driverId: const DriverId(_a)); // E1
      SessionEpoch.bump();
      await repo.getLogs(driverId: const DriverId(_b)); // E2

      backend.failAll = true;
      network.connected = false;
      expect((await repo.getLogs(driverId: const DriverId(_a))).isLeft(), isTrue);
      expect(rightOf(await repo.getLogs(driverId: const DriverId(_b)))!.driverId.value, _b);
    });

    test('V4-b: cache survives repeated calls inside a single epoch', () async {
      for (var i = 0; i < 5; i++) {
        await repo.getLogs(driverId: const DriverId(_b));
      }
      backend.failAll = true;
      network.connected = false;
      for (var i = 0; i < 5; i++) {
        expect((await repo.getLogs(driverId: const DriverId(_b))).isRight(),
            isTrue,
            reason: 'call $i lost the cache');
      }
    });

    test('V4-c: ownership mismatch on screen data is rejected', () async {
      backend.mislabelledDriverId = _a;
      final r = await repo.getScreen(driverId: const DriverId(_b));
      expect(r.isLeft(), isTrue);
      expect(leftOf(r).message, 'inspectionOwnerMismatch');

      backend.failAll = true;
      network.connected = false;
      expect((await repo.getScreen(driverId: const DriverId(_b))).isLeft(), isTrue,
          reason: 'the mismatched screen must not have been cached');
    });

    test('V4-d: ownership mismatch on cycle data is rejected', () async {
      backend.mislabelledDriverId = _a;
      final r = await repo.getCycle(driverId: const DriverId(_b), days: 8);
      expect(r.isLeft(), isTrue);
      expect(leftOf(r).message, 'inspectionOwnerMismatch');
    });

    test('V4-e: unknown driver identity is stored but never "verified"',
        () async {
      backend.mislabelledDriverId = 0; // the contract's absent-driver case
      final r = await repo.getLogs(driverId: const DriverId(_b));
      expect(r.isRight(), isTrue, reason: 'unknown is not a mismatch');

      backend.failAll = true;
      network.connected = false;
      expect((await repo.getLogs(driverId: const DriverId(_b))).isLeft(), isTrue,
          reason: 'serving a named driver needs verified ownership');

      final outcome = await repo.sendLogs(
        driverId: const DriverId(_b),
        method: TransferMethod.usb,
        comment: 'review',
      );
      expect(outcome.isLeft(), isTrue);
      expect(leftOf(outcome).message, 'inspectionNoVerifiedData');
    });
  });
}

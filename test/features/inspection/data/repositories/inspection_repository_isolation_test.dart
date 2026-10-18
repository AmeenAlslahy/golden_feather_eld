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

/// fpdart 1.2.0 has no getOrNull; unwrap the Right side explicitly.
T? rightOf<T>(Either<Failure, T> either) => either.fold((_) => null, (v) => v);

/// One shared "backend is down" error keeps every failure path identical.
const _down = ServerError(code: 'server.down');

// -----------------------------------------------------------------------------
// Test doubles
// -----------------------------------------------------------------------------

/// Network toggle so a test can populate the cache while online and then
/// simulate an outage. A permanently-offline fake cannot populate the cache.
class _ToggleNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  bool get isConnected => connected;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

/// Succeeds while `failAll == false`, fails afterwards, and returns data that is
/// unmistakably driver-specific so cross-driver leakage is visible in assertions.
class _ScriptedBackend implements InspectionBackend {
  bool failAll = false;

  /// Per-driver response latency gate, used by the concurrency test.
  final Map<int, Completer<void>> gates = {};

  int screenCalls = 0;
  int cycleCalls = 0;
  int logCalls = 0;

  Future<void> _gate(DriverId? id) async {
    final g = id == null ? null : gates[id.value];
    if (g != null) await g.future;
  }

  @override
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId}) async {
    screenCalls++;
    await _gate(driverId);
    if (failAll) return err(_down);
    return ok(screenFor(driverId));
  }

  @override
  Future<Result<List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) async {
    cycleCalls++;
    await _gate(driverId);
    if (failAll) return err(_down);
    return ok([cycleFor(driverId)]);
  }

  @override
  Future<Result<DotInspectionLog>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) async {
    logCalls++;
    await _gate(driverId);
    if (failAll) return err(_down);
    return ok(logFor(driverId, date ?? DateTime.utc(2026, 9, 23)));
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
  }) async {
    if (failAll) return err(_down);
    return ok(<String, dynamic>{'status': 'PENDING'});
  }

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
  }) async {
    if (failAll) return err(_down);
    return ok(<String, dynamic>{'status': 'PENDING'});
  }

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
  }) async {
    if (failAll) return err(_down);
    return ok(<String, dynamic>{'status': 'OK'});
  }

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) async {
    if (failAll) return err(_down);
    return ok(<String, dynamic>{'data': <dynamic>[]});
  }
}

// -----------------------------------------------------------------------------
// Entity builders — every field is driver-tagged so leakage is unambiguous.
// -----------------------------------------------------------------------------

const _a = 101; // Driver A
const _b = 202; // Driver B

DotInspectionScreen screenFor(DriverId? id) => DotInspectionScreen(
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

DotInspectionCycleDay cycleFor(DriverId? id) => DotInspectionCycleDay(
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

DotInspectionLog logFor(DriverId? id, DateTime date) => DotInspectionLog(
      driverId: id ?? const DriverId(0),
      driverName: 'driver-${id?.value ?? 'none'} Said',
      logDate: date,
      displayDate: '2026-09-23',
      displayLocation: 'loc-${id?.value ?? 'none'}',
      certified: true,
      certifiedAt: date,
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

// -----------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsDir;
  late _ScriptedBackend backend;
  late _ToggleNetworkInfo network;
  late InspectionRepositoryImpl repo;

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    SessionEpoch.resetForTests();
    docsDir = Directory.systemTemp.createTempSync('fmcsa_docs');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return docsDir.path;
      }
      return null;
    });

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

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
    SessionEpoch.resetForTests();
  });

  // ---------------------------------------------------------------------------
  // TEST 1 — Driver B must never receive Driver A's cached data.
  // ---------------------------------------------------------------------------
  test(
      'TEST 1: driver B offline never receives driver A cached inspection data',
      () async {
    // A loads successfully while online.
    final aScreen = await repo.getScreen(driverId: const DriverId(_a));
    expect(aScreen.isRight(), isTrue);
    await repo.getCycle(driverId: const DriverId(_a), days: 8);
    await repo.getLogs(driverId: const DriverId(_a));
    final aPacket = await repo.getInformationPacket(driverId: const DriverId(_a));
    expect(aPacket.isRight(), isTrue);

    // Backend goes down AND the device goes offline.
    backend.failAll = true;
    network.connected = false;

    // B asks for the same resources.
    final bLogs = await repo.getLogs(driverId: const DriverId(_b));
    expect(
      bLogs.isLeft(),
      isTrue,
      reason: 'B must not receive A\'s cached log',
    );

    final bScreen = await repo.getScreen(driverId: const DriverId(_b));
    expect(bScreen.isLeft(), isTrue, reason: 'B must not receive A\'s screen');

    final bCycle =
        await repo.getCycle(driverId: const DriverId(_b), days: 8);
    expect(bCycle.isLeft(), isTrue, reason: 'B must not receive A\'s cycle');

    final bPacket = await repo.getInformationPacket(driverId: const DriverId(_b));
    expect(bPacket.isLeft(), isTrue, reason: 'B must not receive A\'s packet');
  });

  // ---------------------------------------------------------------------------
  // TEST 2 — Same date, two drivers: cached records stay isolated.
  // ---------------------------------------------------------------------------
  test('TEST 2: two drivers requesting the same date keep separate records',
      () async {
    final date = DateTime.utc(2026, 9, 23);

    final a = await repo.getLogs(driverId: const DriverId(_a), date: date);
    expect(rightOf(a)!.driverId.value, _a);

    final b = await repo.getLogs(driverId: const DriverId(_b), date: date);
    expect(rightOf(b)!.driverId.value, _b);

    // Both go offline; each driver must still read back its OWN record.
    backend.failAll = true;
    network.connected = false;

    final aAgain = await repo.getLogs(driverId: const DriverId(_a), date: date);
    expect(aAgain.isRight(), isTrue);
    expect(rightOf(aAgain)!.driverId.value, _a,
        reason: 'A must read A');

    final bAgain = await repo.getLogs(driverId: const DriverId(_b), date: date);
    expect(bAgain.isRight(), isTrue);
    expect(rightOf(bAgain)!.driverId.value, _b,
        reason: 'B must read B — not A\'s record');
  });

  // ---------------------------------------------------------------------------
  // TEST 3 — Session epoch change invalidates everything from the old session.
  // ---------------------------------------------------------------------------
  test('TEST 3: data cached in a previous session epoch is never returned',
      () async {
    await repo.getLogs(driverId: const DriverId(_a));
    await repo.getScreen(driverId: const DriverId(_a));
    await repo.getCycle(driverId: const DriverId(_a), days: 8);

    // Identity boundary: logout + login of the SAME driver.
    SessionEpoch.bump();

    backend.failAll = true;
    network.connected = false;

    final logs = await repo.getLogs(driverId: const DriverId(_a));
    expect(logs.isLeft(), isTrue,
        reason: 'previous-session cache must not survive an epoch bump');

    final screen = await repo.getScreen(driverId: const DriverId(_a));
    expect(screen.isLeft(), isTrue);
  });

  // ---------------------------------------------------------------------------
  // TEST 4 — FMCSA file must never carry another driver's data or identity.
  // ---------------------------------------------------------------------------
  test(
      'TEST 4: FMCSA generation for driver B never embeds driver A data',
      () async {
    // A populates every cache slot the generator consumes.
    await repo.getScreen(driverId: const DriverId(_a));
    await repo.getCycle(driverId: const DriverId(_a), days: 8);
    await repo.getLogs(driverId: const DriverId(_a));
    expect(backend.screenCalls, 1);
    expect(backend.cycleCalls, 1);
    expect(backend.logCalls, 1);

    // B also has a verified record of his own, so a legitimate file exists.
    await repo.getLogs(driverId: const DriverId(_b));

    // B goes offline and requests an ELD output file.
    backend.failAll = true;
    network.connected = false;

    final outcome = await repo.sendLogs(
      driverId: const DriverId(_b),
      method: TransferMethod.usb,
      comment: 'B roadside',
    );

    expect(outcome.isRight(), isTrue,
        reason: 'offline generation is a supported flow');

    final text = rightOf(outcome)!;
    expect(text.text.startsWith('OFFLINE_GENERATED:'), isTrue,
        reason: 'expected a locally generated file, got: ${text.text}');
    final path = text.text.substring('OFFLINE_GENERATED:'.length);
    final csv = File(path).readAsStringSync();

    // Every field the repository caches is driver-tagged, so leakage shows up
    // as one of these tokens. A bare "101" would false-positive on the file's
    // own MMddyy creation date, so only tagged tokens are asserted.
    for (final token in <String>[
      'carrier-$_a',
      'USDOT-$_a',
      'ELD-$_a',
      'REG-$_a',
      'VIN-$_a',
      'VEH-$_a',
      'driver-$_a',
      'U-$_a',
      'loc-$_a',
      'screen-$_a',
    ]) {
      expect(csv.contains(token), isFalse,
          reason: "driver A token '$token' leaked into driver B's ELD file:\n$csv");
    }

    // The DriverID column (10th field of the type-1 header line) must be B.
    final header = csv.split('\n').firstWhere((l) => l.startsWith('1,'));
    final driverIdField = header.split(',')[9];
    expect(driverIdField, '$_b',
        reason: 'DriverID must be B ($_b), got "$driverIdField" in: $header');
  });

  // ---------------------------------------------------------------------------
  // TEST 5 — Same driver offline keeps working (behaviour preservation).
  // ---------------------------------------------------------------------------
  test('TEST 5: the same driver still reads their own cache while offline',
      () async {
    await repo.getLogs(driverId: const DriverId(_a));
    await repo.getScreen(driverId: const DriverId(_a));

    backend.failAll = true;
    network.connected = false;

    final logs = await repo.getLogs(driverId: const DriverId(_a));
    expect(logs.isRight(), isTrue, reason: 'offline cache for the same driver');
    expect(rightOf(logs)!.driverId.value, _a);

    final screen = await repo.getScreen(driverId: const DriverId(_a));
    expect(screen.isRight(), isTrue);
    expect(rightOf(screen)!.driverId.value, _a);
  });

  // ---------------------------------------------------------------------------
  // TEST 6 — Overlapping requests for different drivers stay isolated.
  // ---------------------------------------------------------------------------
  test('TEST 6: overlapping requests for different drivers stay isolated',
      () async {
    final gateA = Completer<void>();
    final gateB = Completer<void>();
    backend.gates[_a] = gateA;
    backend.gates[_b] = gateB;

    final futureA =
        repo.getLogs(driverId: const DriverId(_a), date: DateTime.utc(2026, 9, 23));
    final futureB =
        repo.getLogs(driverId: const DriverId(_b), date: DateTime.utc(2026, 9, 23));

    // B completes first, then A — the reverse completion order must not matter.
    gateB.complete();
    final b = await futureB;
    expect(rightOf(b)!.driverId.value, _b);

    gateA.complete();
    final a = await futureA;
    expect(rightOf(a)!.driverId.value, _a);

    // Offline read-back after the race.
    backend.failAll = true;
    network.connected = false;

    final aOffline =
        await repo.getLogs(driverId: const DriverId(_a), date: DateTime.utc(2026, 9, 23));
    final bOffline =
        await repo.getLogs(driverId: const DriverId(_b), date: DateTime.utc(2026, 9, 23));

    expect(rightOf(aOffline)!.driverId.value, _a);
    expect(rightOf(bOffline)!.driverId.value, _b);
  });
}
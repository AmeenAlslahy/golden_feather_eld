import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/inspection/data/datasources/inspection_local_cache.dart';
import 'package:golden_feather_eld/features/inspection/domain/transfer_audit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late PrefsInspectionLocalCache cache;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    storage = LocalStorageService();
    await storage.init();
    cache = PrefsInspectionLocalCache(storage);
  });

  test('saves and loads DotInspectionScreen with driver isolation', () async {
    final screen = DotInspectionScreen(
      screenTitle: 'DOT Inspection Mode',
      guidanceText: 'Present this screen to law enforcement',
      handOverDeviceNotice: 'Hand over device to officer',
      carrierComplianceStatement: 'FMCSA Compliant',
      carrierName: 'Golden Feather Transport',
      usdotNumber: '1234567',
      eldIdentifier: 'ELD-001',
      eldRegistrationId: 'REG-123',
      driverId: const DriverId(101),
      driverName: 'Driver One',
      inspectionDate: DateTime.parse('2026-10-14T12:00:00Z'),
      cycleDaysCovered: 8,
      canStartInspection: true,
      canSendLogs: true,
      canEmailLogs: false,
      canViewInformationPacket: true,
      inspectionActive: false,
      readOnlyMode: false,
      activeInspectionId: null,
      inspectorName: null,
    );

    await cache.saveScreen(screen, ownerId: 101);

    // Same driver matches
    final loaded = cache.loadScreen(ownerId: 101);
    expect(loaded, isNotNull);
    expect(loaded!.driverId.value, equals(101));
    expect(loaded.carrierName, equals('Golden Feather Transport'));
    expect(loaded.usdotNumber, equals('1234567'));

    // Different driver returns null (isolated)
    final otherDriver = cache.loadScreen(ownerId: 999);
    expect(otherDriver, isNull);
  });

  test('saves and loads transfer audit rows with isolation', () async {
    final rows = [
      const TransferAuditRow(
        channel: 'EMAIL',
        recipient: 'officer@dot.gov',
        status: 'SUCCESS',
        transferredAt: '2026-10-14T10:00:00Z',
        message: 'Inspection transfer complete',
        period: '8 days',
        recordCount: '8',
      ),
    ];

    await cache.saveTransfers(rows, ownerId: 101);

    final loaded = cache.loadTransfers(ownerId: 101);
    expect(loaded, isNotNull);
    expect(loaded!.length, equals(1));
    expect(loaded[0].channel, equals('EMAIL'));
    expect(loaded[0].status, equals('SUCCESS'));

    // Other driver gets null
    expect(cache.loadTransfers(ownerId: 202), isNull);
  });

  test('clears all inspection caches on clear()', () async {
    final screen = DotInspectionScreen(
      screenTitle: 'DOT Inspection Mode',
      guidanceText: '',
      handOverDeviceNotice: '',
      carrierComplianceStatement: '',
      carrierName: 'Test Carrier',
      usdotNumber: '123',
      eldIdentifier: 'E1',
      eldRegistrationId: 'R1',
      driverId: const DriverId(101),
      driverName: 'Driver',
      inspectionDate: DateTime.now(),
      cycleDaysCovered: 8,
      canStartInspection: true,
      canSendLogs: true,
      canEmailLogs: false,
      canViewInformationPacket: false,
      inspectionActive: false,
      readOnlyMode: false,
      activeInspectionId: null,
      inspectorName: null,
    );
    await cache.saveScreen(screen, ownerId: 101);

    await cache.clear();

    expect(cache.loadScreen(ownerId: 101), isNull);
    expect(cache.loadCycle(ownerId: 101), isNull);
    expect(cache.loadAllLogs(ownerId: 101), isEmpty);
    expect(cache.loadPacket(ownerId: 101), isNull);
    expect(cache.loadTransfers(ownerId: 101), isNull);
  });
}

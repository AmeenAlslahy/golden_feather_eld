import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/data/datasources/dashboard_local_cache.dart';
import 'package:golden_feather_eld/features/hos/data/providers/status_dashboard_repository_providers.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/status_dashboard_repository_impl.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/inspection/data/datasources/inspection_local_cache.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_offline_queue.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

class _Backend extends Mock implements StatusDashboardBackend {}

class _ConnectedInfo implements NetworkInfo {
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();

  @override
  bool get isConnected => true;
}

class _MemoryDashboardDisk implements DashboardLocalCache {
  CachedDashboard? snapshot;
  WeeklyRecap? recap;

  @override
  Future<void> saveDashboard(StatusDashboard dashboard,
      {required DateTime takenAt}) async {
    snapshot = CachedDashboard(dashboard: dashboard, takenAt: takenAt);
  }

  @override
  CachedDashboard? loadDashboard() => snapshot;

  @override
  Future<void> saveRecap(WeeklyRecap recap) async {
    this.recap = recap;
  }

  @override
  WeeklyRecap? loadRecap() => recap;

  @override
  Future<void> clear() async {
    snapshot = null;
    recap = null;
  }
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: '646',
              username: 'naseem646',
              email: 'naseem@test.com',
              fullName: 'Naseem',
              role: UserRole.fieldWorker,
              createdAt: DateTime(2026),
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StatusDashboard _sampleDashboard() => const StatusDashboard(
      driver: DriverRef(
        id: DriverId(646),
        name: 'Naseem',
        displayText: 'Naseem - 646',
      ),
      operationalAlerts: OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      ),
      currentDutyStatus: DutyStatusCode.onDutyNotDriving,
      remainingCircle: RemainingCircle(
        remaining: Duration(hours: 8),
        label: 'Remaining',
        progress: 0.5,
      ),
      hosIndicators: HosIndicators(
        drive: HosIndicator(
          label: 'DRIVE',
          value: Duration(hours: 2, minutes: 23),
          type: IndicatorType.used,
        ),
        shift: HosIndicator(
          label: 'SHIFT',
          value: Duration(hours: 5),
          type: IndicatorType.used,
        ),
        breakTime: HosIndicator(
          label: 'BREAK',
          value: Duration(minutes: 30),
          type: IndicatorType.remaining,
        ),
        cycle: HosIndicator(
          label: 'CYCLE',
          value: Duration(hours: 61),
          type: IndicatorType.used,
        ),
      ),
      regulatoryConstraints: RegulatoryConstraints(
        ruleSet: CycleRule.usa70_8,
        limits: [],
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // P2.1 — فهارس SQLite
  // ==========================================================================
  group('P2 — SQLite queue indexes', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late Directory dir;

    setUp(() async {
      await SQLiteOfflineQueue.resetForTests();
      dir = await Directory.systemTemp.createTemp('p2_sqlite');
    });

    tearDown(() async {
      await SQLiteOfflineQueue.resetForTests();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    Future<Set<String>> indexNames(String path) async {
      final db = await databaseFactory.openDatabase(path);
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      await db.close();
      return rows.map((r) => r['name'] as String).toSet();
    }

    test('fresh database gets the three query indexes', () async {
      final path = p.join(dir.path, 'fresh.db');
      final queue = SQLiteOfflineQueue(dbPathOverride: path);

      await queue.count; // يفتح القاعدة ويشغّل onCreate

      final names = await indexNames(path);
      expect(names, contains('idx_pending_ready'));
      expect(names, contains('idx_quarantine_state'));
      expect(names, contains('idx_dead_letters_failedAt'));
    });

    test('v3 database is upgraded additively and gets the indexes', () async {
      final path = p.join(dir.path, 'legacy.db');
      final v3 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE pending_events (
                id TEXT PRIMARY KEY, type TEXT NOT NULL, payload TEXT NOT NULL,
                createdAt INTEGER NOT NULL, priority INTEGER NOT NULL,
                retryCount INTEGER NOT NULL, nextRetryAt INTEGER
              )
            ''');
            await db.execute('''
              CREATE TABLE dead_letters (
                id TEXT PRIMARY KEY, type TEXT NOT NULL, payload TEXT NOT NULL,
                createdAt INTEGER NOT NULL, failedAt INTEGER NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE quarantine (
                id TEXT PRIMARY KEY, type TEXT NOT NULL, payload TEXT NOT NULL,
                createdAt INTEGER NOT NULL, priority INTEGER NOT NULL,
                retryCount INTEGER NOT NULL, ownerDriverId INTEGER,
                proof TEXT NOT NULL DEFAULT 'none', state TEXT NOT NULL,
                reason TEXT NOT NULL DEFAULT '', quarantinedAt INTEGER NOT NULL
              )
            ''');
          },
        ),
      );
      await v3.insert('pending_events', {
        'id': 'legacy-1',
        'type': 'duty_status',
        'payload': '{}',
        'createdAt': 1,
        'priority': 0,
        'retryCount': 0,
      });
      await v3.close();

      final queue = SQLiteOfflineQueue(dbPathOverride: path);
      expect(await queue.count, 1, reason: 'لا فقد صفوف أثناء الترقية');

      final names = await indexNames(path);
      expect(names, contains('idx_pending_ready'));
      expect(names, contains('idx_quarantine_state'));
      expect(names, contains('idx_dead_letters_failedAt'));
    });
  });

  // ==========================================================================
  // P2.2 — اللوحة كاش-أولاً
  // ==========================================================================
  group('P2 — dashboard cache-first', () {
    test(
        'cached snapshot is served instantly; server refresh runs in '
        'background', () async {
      final backend = _Backend();
      when(() => backend.getDashboard(driverId: any(named: 'driverId'))).thenAnswer(
        (_) async => err(
          const NetworkError(
            code: 'dashboard.offline',
            l10nKey: 'dashboardOffline',
          ),
        ),
      );

      final disk = _MemoryDashboardDisk()
        ..snapshot = CachedDashboard(
          dashboard: _sampleDashboard(),
          takenAt: DateTime.utc(2026, 3, 1, 8),
        );
      // الساعة الموثوقة = لحظة القياس نفسها: لا زمن يمرّ ⇒ يخرج حارس
      // التقليم مبكراً ويبقى الاختبار معزولاً عن حساب الفهرس الحيّ.
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _ConnectedInfo(),
        disk: disk,
        trustedNowUtc: () => DateTime.utc(2026, 3, 1, 8),
      );

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          authStateProvider.overrideWith((ref) => _Auth()),
          trustedTimeProvider.overrideWithValue(
            FakeTrustedTimeProvider(initialUtcTime: DateTime.utc(2026, 3, 1, 8)),
          ),
          statusDashboardRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final dashboard =
          await container.read(statusDashboardProvider.future);

      // العرض الفوري: لقطة الكاش — بلا أي نداء شبكة قبلها.
      expect(dashboard.remainingCircle.remaining,
          const Duration(hours: 8));
      verifyNever(() => backend.getDashboard(driverId: any(named: 'driverId')));

      // النبضة الخلفية تجلب من الخادم (وتفشل هنا) دون مساس اللوحة
      // أو الختم: اللقطة تبقى معروضة بلحظة قياسها الأصلية.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      verify(() => backend.getDashboard(driverId: any(named: 'driverId'))).called(1);
      expect(
        container.read(statusDashboardProvider).value?.remainingCircle.remaining,
        const Duration(hours: 8),
        reason: 'فشل التحديث الخلفي لا يمسح اللقطة المعروضة',
      );
      expect(
        container.read(statusDashboardSnapshotTimestampProvider),
        DateTime.utc(2026, 3, 1, 8),
        reason: 'الختم لحظة قياس اللقطة الأصلية، لا "الآن"',
      );
    });

    test('cold start without cache still goes to the network', () async {
      final backend = _Backend();
      when(() => backend.getDashboard(driverId: any(named: 'driverId')))
          .thenAnswer((_) async => ok(_sampleDashboard()));

      final repo = StatusDashboardRepositoryImpl(
        backend,
        _ConnectedInfo(),
        disk: _MemoryDashboardDisk(),
        trustedNowUtc: () => DateTime.utc(2026, 3, 1, 12),
      );

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          authStateProvider.overrideWith((ref) => _Auth()),
          statusDashboardRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final dashboard =
          await container.read(statusDashboardProvider.future);

      verify(() => backend.getDashboard(driverId: any(named: 'driverId'))).called(1);
      expect(dashboard.driver.id.value, 646);
    });
  });

  // ==========================================================================
  // P2.3 — مساواة DashboardData
  // ==========================================================================
  group('P2 — DashboardData value equality', () {
    test('identical values are equal and hash equal', () {
      const a = DashboardData(
        driverName: 'A',
        vehicleId: 'V1',
        vehicleDisplayName: 'Truck 1',
        deviceId: 9,
      );
      const b = DashboardData(
        driverName: 'A',
        vehicleId: 'V1',
        vehicleDisplayName: 'Truck 1',
        deviceId: 9,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('any changed field breaks equality', () {
      const a = DashboardData(
        driverName: 'A',
        vehicleId: 'V1',
        vehicleDisplayName: 'Truck 1',
      );

      expect(a == a.copyWith(driverName: 'B'), isFalse);
      expect(a == a.copyWith(vehicleId: 'V2'), isFalse);
      expect(a == a.copyWith(trailerId: 'T9'), isFalse);
      expect(a == a.copyWith(documentsInfo: 'docs'), isFalse);
    });
  });

  // ==========================================================================
  // P2.4 — كاش سجلات التفتيش: حفظ متعدد + إبطال بالمسح
  // ==========================================================================
  group('P2 — inspection logs cache memoization', () {
    late LocalStorageService storage;
    late PrefsInspectionLocalCache cache;

    Map<String, dynamic> logJson(int driverId, String date) => {
          'driver': {'id': driverId, 'name': 'Driver $driverId'},
          'logDate': date,
          'displayDate': date,
          'events': <Map<String, dynamic>>[],
        };

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({});
      storage = LocalStorageService();
      await storage.init();
      cache = PrefsInspectionLocalCache(storage);
    });

    test('sequential saves preserve earlier logs and round-trip', () async {
      final first = DotInspectionMapper.fromLogJson(
          logJson(101, '2026-03-01'));
      final second = DotInspectionMapper.fromLogJson(
          logJson(101, '2026-03-02'));

      await cache.saveLog('101:2026-03-01', first);
      await cache.saveLog('101:2026-03-02', second);

      final all = cache.loadAllLogs(ownerId: 101);
      expect(all.keys, contains('101:2026-03-01'),
          reason: 'حفظ لاحق لا يمحو سابقاً');
      expect(all.keys, contains('101:2026-03-02'));
      expect(all['101:2026-03-01']?.driverId.value, 101);
    });

    test('clear() drops both stored data and the in-memory map', () async {
      await cache.saveLog(
        '101:2026-03-01',
        DotInspectionMapper.fromLogJson(logJson(101, '2026-03-01')),
      );
      expect(cache.loadAllLogs(ownerId: 101), isNotEmpty);

      await cache.clear();

      expect(cache.loadAllLogs(ownerId: 101), isEmpty);
      // وُجد الصف في الذاكرة قبل المسح؛ لو لم يُبطَل لعاد رغم حذف المفتاح.
      await cache.saveLog(
        '101:2026-03-05',
        DotInspectionMapper.fromLogJson(logJson(101, '2026-03-05')),
      );
      final after = cache.loadAllLogs(ownerId: 101);
      expect(after.keys, ['101:2026-03-05']);
    });
  });
}

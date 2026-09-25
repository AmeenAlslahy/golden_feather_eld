import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/core_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/sync_local_data_source.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_repository.dart';
import 'sync_engine_provider.dart';

/// مزودات المزامنة
final syncLocalDataSourceProvider = Provider<SyncLocalDataSource>((ref) {
  return SyncLocalDataSourceImpl();
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final localDataSource = ref.watch(syncLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final dispatcher = ref.watch(remoteEventDispatcherProvider);
  return SyncRepositoryImpl(
    localDataSource: localDataSource,
    networkInfo: networkInfo,
    dispatcher: dispatcher,
  );
});

/// مزود حالة المزامنة
final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return SyncNotifier(repository);
});

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncRepository _repository;
  Timer? _autoSyncTimer;

  SyncNotifier(this._repository) : super(const SyncState()) {
    _loadPendingItems();
    _startAutoSync();
  }

  Future<void> _loadPendingItems() async {
    final items = await _repository.getPendingItems();
    state = state.copyWith(
      pendingItems: items,
      totalPending: items.length,
      totalFailed: items.where((i) => i.status == SyncStatus.failed).length,
    );
  }

  void _startAutoSync() {
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      syncNow();
    });
  }

  /// مزامنة الآن
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true);

    final result = await _repository.processQueue();

    result.match(
      (failure) {
        state = state.copyWith(isSyncing: false);
        AppLogger.error('Sync failed: ${failure.message}');
      },
      (count) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncTime: count > 0 ? DateTime.now() : state.lastSyncTime,
        );
        _loadPendingItems();
        if (count > 0) {
          AppLogger.info('✅ Synced $count items');
        }
      },
    );
  }

  /// إضافة حدث للمزامنة
  Future<void> enqueue(SyncEventType type, Map<String, dynamic> data) async {
    await _repository.enqueue(type, data);
    await _loadPendingItems();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

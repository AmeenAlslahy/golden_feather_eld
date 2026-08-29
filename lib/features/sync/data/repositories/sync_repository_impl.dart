import 'package:fpdart/fpdart.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_data_source.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../domain/entities/pending_event.dart';

/// تنفيذ مستودع المزامنة
class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final RemoteEventDispatcher _dispatcher;

  static const int _maxRetries = 3;

  SyncRepositoryImpl({
    required SyncLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required RemoteEventDispatcher dispatcher,
  })  : _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _dispatcher = dispatcher;

  @override
  Future<Either<Failure, bool>> enqueue(SyncEventType type, Map<String, dynamic> data) async {
    try {
      final items = await _localDataSource.getPendingItems();
      final newItem = SyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        data: data,
        createdAt: DateTime.now(),
      );
      items.add(newItem);
      await _localDataSource.saveItems(items);
      AppLogger.info('📥 Event queued: ${type.name} (${items.length} pending)');
      return const Right(true);
    } catch (e) {
      AppLogger.error('Failed to enqueue event', e);
      return const Left(CacheFailure(message: 'Failed to save event'));
    }
  }

  @override
  Future<Either<Failure, int>> processQueue() async {
    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        return const Right(0); // لا يوجد اتصال
      }

      final items = await _localDataSource.getPendingItems();
      if (items.isEmpty) return const Right(0);

      int successCount = 0;
      final updatedItems = <SyncItem>[];

      for (final item in items) {
        try {
          final success = await _sendToServer(item);
          if (success) {
            successCount++;
          } else {
            if (item.retryCount < _maxRetries) {
              updatedItems.add(item.copyWith(
                retryCount: item.retryCount + 1,
              ));
            }
          }
        } catch (e) {
          if (item.retryCount < _maxRetries) {
            updatedItems.add(item.copyWith(
              retryCount: item.retryCount + 1,
              errorMessage: e.toString(),
            ));
          }
        }
      }

      await _localDataSource.saveItems(updatedItems);

      if (successCount > 0) {
        await _localDataSource.saveLastSyncTime(DateTime.now());
      }

      AppLogger.info('📊 Queue processed: $successCount succeeded, ${updatedItems.length} pending');
      return Right(successCount);
    } catch (e) {
      AppLogger.error('Failed to process queue', e);
      return const Left(SyncFailure(message: 'Sync failed'));
    }
  }

  /// إرسال حدث للخادم
  Future<bool> _sendToServer(SyncItem item) async {
    final event = PendingEvent(
      id: item.id,
      type: item.type.name,
      payload: item.data,
      createdAt: item.createdAt,
    );
    final result = await _dispatcher.dispatch(event);
    return result.match(
      (failure) {
        AppLogger.error('Failed to send event: ${failure.message}');
        return false;
      },
      (_) => true,
    );
  }

  @override
  Future<List<SyncItem>> getPendingItems() async {
    return _localDataSource.getPendingItems();
  }

  @override
  Future<int> getPendingCount() async {
    final items = await _localDataSource.getPendingItems();
    return items.length;
  }

  @override
  Future<Either<Failure, bool>> clearQueue() async {
    try {
      await _localDataSource.clear();
      return const Right(true);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to clear queue'));
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return _localDataSource.getLastSyncTime();
  }
}

import 'package:equatable/equatable.dart';

/// نوع الحدث المراد مزامنته
enum SyncEventType {
  statusChange,
  locationUpdate,
  dvirReport,
  certifyLog,
  inspectionReport,
}

/// حالة المزامنة
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

/// عنصر في طابور المزامنة
class SyncItem extends Equatable {
  final String id;
  final SyncEventType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final SyncStatus status;
  final int retryCount;
  final String? errorMessage;

  const SyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  SyncItem copyWith({
    SyncStatus? status,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncItem(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      // النسخة السابقة كانت تمسح رسالة الخطأ عند أي copyWith بدون تمريرها —
      // محاولة retry بلا سبب كانت تنسي آخر خطأ معروف.
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  // data خارج المقارنة عمداً: Map بعد دورة JSON/خزنة كائن جديد
  // (identity ≠ المضمون)، فتساوٍ مضلل بالاتجاهين.
  List<Object?> get props =>
      [id, type, createdAt, status, retryCount, errorMessage];
}

/// حالة المزامنة العامة
class SyncState extends Equatable {
  final List<SyncItem> pendingItems;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int totalPending;
  final int totalFailed;

  const SyncState({
    this.pendingItems = const [],
    this.isSyncing = false,
    this.lastSyncTime,
    this.totalPending = 0,
    this.totalFailed = 0,
  });

  SyncState copyWith({
    List<SyncItem>? pendingItems,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? totalPending,
    int? totalFailed,
  }) {
    return SyncState(
      pendingItems: pendingItems ?? this.pendingItems,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      totalPending: totalPending ?? this.totalPending,
      totalFailed: totalFailed ?? this.totalFailed,
    );
  }

  @override
  List<Object?> get props =>
      [pendingItems, isSyncing, lastSyncTime, totalPending, totalFailed];
}

import '../../domain/entities/sync_item.dart';

/// نموذج عنصر المزامنة
class SyncItemModel extends SyncItem {
  const SyncItemModel({
    required super.id,
    required super.type,
    required super.data,
    required super.createdAt,
    super.status = SyncStatus.pending,
    super.retryCount = 0,
    super.errorMessage,
  });

  factory SyncItemModel.fromJson(Map<String, dynamic> json) {
    return SyncItemModel(
      id: json['id'] ?? '',
      type: SyncEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncEventType.statusChange,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      retryCount: json['retry_count'] ?? 0,
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  factory SyncItemModel.fromEntity(SyncItem item) {
    return SyncItemModel(
      id: item.id,
      type: item.type,
      data: item.data,
      createdAt: item.createdAt,
      status: item.status,
      retryCount: item.retryCount,
      errorMessage: item.errorMessage,
    );
  }
}

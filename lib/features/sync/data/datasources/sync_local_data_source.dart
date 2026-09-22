import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/sync_item.dart';
import '../models/sync_item_model.dart';

/// مصدر بيانات المزامنة المحلي
abstract class SyncLocalDataSource {
  Future<List<SyncItem>> getPendingItems();
  Future<void> saveItems(List<SyncItem> items);
  Future<void> saveLastSyncTime(DateTime time);
  Future<DateTime?> getLastSyncTime();
  Future<void> clear();
}

/// تنفيذ مصدر بيانات المزامنة المحلي
class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  static const String _queueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_time';

  @override
  Future<List<SyncItem>> getPendingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_queueKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = jsonDecode(data);
      final validItems = <SyncItem>[];
      for (final e in list) {
        try {
          validItems.add(SyncItemModel.fromJson(e));
        } catch (_) {
          // Skip invalid individual items but keep the rest
        }
      }
      return validItems;
    } catch (e) {
      // If the entire JSON is fundamentally corrupted, backup the data so it's not permanently lost
      await prefs.setString('${_queueKey}_corrupted_${DateTime.now().millisecondsSinceEpoch}', data);
      await prefs.remove(_queueKey);
      return [];
    }
  }

  @override
  Future<void> saveItems(List<SyncItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(
        items.map((e) => SyncItemModel.fromEntity(e).toJson()).toList());
    await prefs.setString(_queueKey, data);
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastSyncKey);
    if (data == null) return null;
    return DateTime.tryParse(data);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}

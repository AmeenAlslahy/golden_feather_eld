import 'dart:convert';

import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/utils/logger.dart';

/// تخزين محلي لقائمة المركبات بصيغة JSON الخام.
///
/// نحفظ **الاستجابة الخام** (`RawJson = Map<String, dynamic>`) لا كائن
/// `Vehicle`: إعادة تحليلها بنفس المحلل المستخدم مع رد الخادم
/// (`parseVehicleList`) تضمن تطابقاً كاملاً دون كتابة تسلسل جديد لكل
/// حقل قد يُنسى لاحقاً.
///
/// **نطاق العزل:** مفتاح واحد، ويُمسح عند تبديل هوية السائق
/// (انظر `GoldenFeatherApp.build` → `ref.listen(authStateProvider)`).
/// سبب الاعتماد على المسح بدل الترميز بالمعرّف: `prefs['id']` هو معرّف
/// **الجهاز** لا السائق فلا يصلح كقفل. والخادم يربط المركبات بتوكن
/// الجلسة في كل طلب، فالكاش عرض محلي فقط ولا يُرسل للخادم.
abstract class VehicleLocalCache {
  Future<void> save(RawJson rawJson);
  RawJson? load();

  /// مسح الكاش المحفوظ (تسجيل خروج / تبديل سائق).
  Future<void> clear();
}

class PrefsVehicleLocalCache implements VehicleLocalCache {
  PrefsVehicleLocalCache(this._storage);

  final LocalStorageService _storage;

  static const String _key = 'vehicle_list_cache';

  @override
  Future<void> save(RawJson rawJson) async {
    try {
      await _storage.prefs.setString(_key, jsonEncode(rawJson));
    } catch (e) {
      AppLogger.warning('VehicleLocalCache.save failed: $e');
    }
  }

  @override
  RawJson? load() {
    try {
      final raw = _storage.prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      AppLogger.warning('VehicleLocalCache.load failed: $e');
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.prefs.remove(_key);
    } catch (e) {
      AppLogger.warning('VehicleLocalCache.clear failed: $e');
    }
  }
}
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/eld_session_snapshot.dart';

/// تخزين لقطة جلسة ELD لكل سائق.
///
/// المفاتيح معزولة بالسائق (`eld_session_snapshot_<driverId>`) لمنع تسرّب
/// جلسة سائق إلى آخر — نفس نمط بقية الكاشات في المشروع.
class EldSessionSnapshotStore {
  final SharedPreferencesWithCache? _prefs;

  const EldSessionSnapshotStore([this._prefs]);

  String _key(int driverId) => 'eld_session_snapshot_$driverId';

  EldSessionSnapshot? load(int driverId) {
    final prefs = _prefs;
    if (prefs == null || driverId <= 0) return null;
    try {
      final raw = prefs.getString(_key(driverId));
      if (raw == null || raw.isEmpty) return null;
      return EldSessionSnapshot.decode(raw);
    } catch (e) {
      AppLogger.warning('EldSessionSnapshotStore: load failed: $e');
      return null;
    }
  }

  Future<void> save(EldSessionSnapshot snapshot) async {
    final prefs = _prefs;
    if (prefs == null || snapshot.driverId <= 0) return;
    try {
      await prefs.setString(_key(snapshot.driverId), EldSessionSnapshot.encode(snapshot));
    } catch (e) {
      AppLogger.warning('EldSessionSnapshotStore: save failed: $e');
    }
  }

  Future<void> clear(int driverId) async {
    final prefs = _prefs;
    if (prefs == null || driverId <= 0) return;
    try {
      await prefs.remove(_key(driverId));
    } catch (e) {
      AppLogger.warning('EldSessionSnapshotStore: clear failed: $e');
    }
  }
}

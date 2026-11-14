import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../datasources/eld_session_snapshot_store.dart';

/// يقرأ `prefs` فقط بعد تهيئة التخزين؛ وقبلها يعمل المتجر بلا تخزين
/// (no-op) بدل رمي `LateInitializationError` في الاختبارات أو الإقلاع المبكر.
final eldSessionSnapshotStoreProvider = Provider<EldSessionSnapshotStore>((ref) {
  final storage = ref.watch(localStorageProvider);
  return EldSessionSnapshotStore(storage.isInitialized ? storage.prefs : null);
});

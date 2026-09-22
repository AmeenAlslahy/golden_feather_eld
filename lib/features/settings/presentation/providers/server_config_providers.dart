import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/config/server_config.dart';
import '../../../../core/storage/ports/secure_storage_port.dart';
import '../../../../core/storage/storage_providers.dart';

/// Manages the persisted [ServerConfig].
///
/// **Persistence:** `SecureStoragePort`, key `server_config_v1`.
///
/// **State:**
/// - `null` → no config saved (app runs in Mock mode).
/// - non-null → config saved (may or may not be verified).
final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfig?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ServerConfigNotifier(storage);
});

class ServerConfigNotifier extends StateNotifier<ServerConfig?> {
  static const String _storageKey = 'server_config_v1';

  final SecureStoragePort _storage;

  ServerConfigNotifier(this._storage) : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await _storage.read(_storageKey);
      if (!mounted) return;
      if (json == null || json.isEmpty) {
        state = null;
        return;
      }
      final map = jsonDecode(json) as Map<String, dynamic>;
      state = _fromJson(map);
    } catch (_) {
      if (mounted) state = null;
    }
  }

  /// Saves the config (does not verify).
  Future<void> save(ServerConfig config) async {
    if (!mounted) return;
    state = config;
    await _storage.write(_storageKey, jsonEncode(_toJson(config)));
  }

  /// Marks the config as verified after a successful probe.
  Future<void> markVerified() async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(
      isVerified: true,
      lastTestedAt: DateTime.now().toUtc(),
    );
    await save(updated);
  }

  /// Clears the config (falls back to Mock mode).
  Future<void> clear() async {
    if (!mounted) return;
    state = null;
    await _storage.delete(_storageKey);
  }

  // ==========================================================================
  // JSON serialization (kept private to this file; the model is Freezed and
  // doesn't carry serialization concerns).
  // ==========================================================================

  static Map<String, dynamic> _toJson(ServerConfig c) => {
        'baseUrl': c.baseUrl,
        'backendType': c.backendType.wire,
        'lastTestedAt': c.lastTestedAt.toIso8601String(),
        'isVerified': c.isVerified,
      };

  static ServerConfig _fromJson(Map<String, dynamic> json) {
    final rawUrl = json['baseUrl'] as String? ?? '';
    return ServerConfig(
      // Re-normalize on load to fix any values saved before the /api-stripping rule
      baseUrl: ServerConfig.normalizeUrl(rawUrl),
      backendType: BackendType.fromWire(json['backendType'] as String?),
      lastTestedAt: DateTime.tryParse(json['lastTestedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

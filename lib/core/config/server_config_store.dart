import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/config/server_config.dart';
import '../storage/ports/secure_storage_port.dart';
import '../storage/storage_providers.dart';

/// Persisted server config. Network reads this store directly.
/// A null value means no saved config, not that the app is in mock mode.
final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfig?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ServerConfigNotifier(storage);
});

class ServerConfigNotifier extends StateNotifier<ServerConfig?> {
  static const String storageKey = 'server_config_v1';

  final SecureStoragePort _storage;

  ServerConfigNotifier(this._storage) : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await _storage.read(storageKey);
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

  Future<void> save(ServerConfig config) async {
    if (!mounted) return;
    state = config;
    await _storage.write(storageKey, jsonEncode(_toJson(config)));
  }

  Future<void> markVerified() async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(
      isVerified: true,
      lastTestedAt: DateTime.now().toUtc(),
    );
    await save(updated);
  }

  Future<void> clear() async {
    if (!mounted) return;
    state = null;
    await _storage.delete(storageKey);
  }

  static Map<String, dynamic> _toJson(ServerConfig c) => {
        'baseUrl': c.baseUrl,
        'backendType': c.backendType.wire,
        'lastTestedAt': c.lastTestedAt.toIso8601String(),
        'isVerified': c.isVerified,
      };

  static ServerConfig _fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      baseUrl: json['baseUrl'] as String? ?? '',
      backendType: BackendType.fromWire(json['backendType'] as String?),
      lastTestedAt: DateTime.tryParse(json['lastTestedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class ConfigBackend {
  /// GET /eld/config
  Future<Result<RawJson>> getConfig();

  /// GET /eld/config/rules
  Future<Result<RawJson>> getConfigRules();

  /// GET /eld/config/settings
  Future<Result<RawJson>> getSettings();

  // --- Legacy methods for P5.5 ---
  Future<Result<RawJson>> getLegacyServerConfig();
}

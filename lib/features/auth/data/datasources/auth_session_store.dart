import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/auth_session.dart';

abstract class AuthSessionStore {
  /// حفظ الجلسة بأمان
  Future<void> saveSession(AuthSession session);

  /// استعادة الجلسة
  Future<AuthSession?> getSession();

  /// التحقق من وجود جلسة
  Future<bool> hasSession();

  /// الحصول على بيانات اعتماد الجلسة (JSESSIONID)
  Future<String?> getSessionCredential();

  /// مسح الجلسة
  Future<void> clearSession();
}

class AuthSessionStoreImpl implements AuthSessionStore {
  final FlutterSecureStorage _secureStorage;
  static const _sessionKey = 'traccar_auth_session';

  AuthSessionStoreImpl({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> saveSession(AuthSession session) async {
    try {
      final jsonString = jsonEncode(session.toJson());
      await _secureStorage.write(key: _sessionKey, value: jsonString);
      AppLogger.info('Session securely stored for origin: ${session.serverOrigin}');
    } catch (e) {
      AppLogger.error('Failed to securely store session', e);
      throw Exception('Secure storage write failed');
    }
  }

  @override
  Future<AuthSession?> getSession() async {
    try {
      final jsonString = await _secureStorage.read(key: _sessionKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AuthSession.fromJson(jsonMap);
    } catch (e) {
      AppLogger.error('Failed to read or parse session from secure storage', e);
      return null;
    }
  }

  @override
  Future<bool> hasSession() async {
    final session = await getSession();
    return session != null && session.sessionCredential.isNotEmpty;
  }

  @override
  Future<String?> getSessionCredential() async {
    final session = await getSession();
    return session?.sessionCredential;
  }

  @override
  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _sessionKey);
      AppLogger.info('Session cleared from secure storage');
    } catch (e) {
      AppLogger.error('Failed to clear session', e);
      // We don't throw here to ensure logout flow can continue even if storage fails
    }
  }
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/domain/entities/user.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/auth_session.dart';
import '../models/auth_session_dto.dart';

abstract class AuthLocalDataSource {
  /// حفظ الجلسة بأمان
  Future<void> saveSession(AuthSession session);

  /// استعادة الجلسة
  Future<AuthSession?> getSession();

  /// مسح الجلسة
  Future<void> clearSession();

  /// حفظ بيانات المستخدم بشكل آمن
  Future<void> saveUser(User user);

  /// استعادة بيانات المستخدم
  Future<User?> getUser();

  /// مسح بيانات المستخدم
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  static const _sessionKey = 'traccar_auth_session';
  static const _userKey = 'app_user_profile';

  AuthLocalDataSourceImpl({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> saveSession(AuthSession session) async {
    try {
      final dto = AuthSessionDto.fromEntity(session);
      final jsonString = jsonEncode(dto.toJson());
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
      final dto = AuthSessionDto.fromJson(jsonMap);
      return dto.toEntity();
    } catch (e) {
      AppLogger.error('Failed to read or parse session from secure storage', e);
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _sessionKey);
      AppLogger.info('Session cleared from secure storage');
    } catch (e) {
      AppLogger.error('Failed to clear session', e);
    }
  }

  @override
  Future<void> saveUser(User user) async {
    try {
      final jsonString = jsonEncode(UserModel.fromEntity(user).toJson());
      await _secureStorage.write(key: _userKey, value: jsonString);
      AppLogger.info('User securely stored: ${user.email}');
    } catch (e) {
      AppLogger.error('Failed to securely store user profile', e);
      throw Exception('Secure storage write failed for user profile');
    }
  }

  @override
  Future<User?> getUser() async {
    try {
      final jsonString = await _secureStorage.read(key: _userKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      AppLogger.error('Failed to read or parse user from secure storage', e);
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await _secureStorage.delete(key: _userKey);
      AppLogger.info('User profile cleared from secure storage');
    } catch (e) {
      AppLogger.error('Failed to clear user profile', e);
    }
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/logger.dart';
import 'package:golden_feather_eld/features/account/domain/entities/user.dart';
import 'package:golden_feather_eld/features/account/data/models/user_model.dart';

abstract class UserStore {
  /// حفظ بيانات المستخدم بشكل آمن
  Future<void> saveUser(User user);

  /// استعادة بيانات المستخدم
  Future<User?> getUser();

  /// مسح بيانات المستخدم
  Future<void> clearUser();
}

class UserStoreImpl implements UserStore {
  final FlutterSecureStorage _secureStorage;
  static const _userKey = 'app_user_profile';

  UserStoreImpl({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

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

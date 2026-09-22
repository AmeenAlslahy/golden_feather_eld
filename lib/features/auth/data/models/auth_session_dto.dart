import 'package:golden_feather_eld/features/auth/data/models/user_model.dart';

import '../../domain/entities/auth_session.dart';

class AuthSessionDto {
  final String serverOrigin;
  final String sessionCredential;
  final UserModel userModel;
  final DateTime createdAt;

  const AuthSessionDto({
    required this.serverOrigin,
    required this.sessionCredential,
    required this.userModel,
    required this.createdAt,
  });

  factory AuthSessionDto.create({
    required String serverOrigin,
    required String sessionCredential,
    required UserModel userModel,
  }) {
    return AuthSessionDto(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      userModel: userModel,
      createdAt: DateTime.now().toUtc(),
    );
  }

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      serverOrigin: json['serverOrigin'] as String,
      sessionCredential: json['sessionCredential'] as String,
      userModel: UserModel.fromJson(json['userModel'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverOrigin': serverOrigin,
      'sessionCredential': sessionCredential,
      'userModel': userModel.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AuthSession toEntity() {
    return AuthSession(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      user: userModel,
      createdAt: createdAt,
    );
  }

  factory AuthSessionDto.fromEntity(AuthSession entity) {
    return AuthSessionDto(
      serverOrigin: entity.serverOrigin,
      sessionCredential: entity.sessionCredential,
      userModel: UserModel.fromEntity(entity.user),
      createdAt: entity.createdAt,
    );
  }
}

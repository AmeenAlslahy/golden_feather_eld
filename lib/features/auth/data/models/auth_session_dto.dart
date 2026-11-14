import '../../../../core/session/auth_session.dart';
import 'package:golden_feather_eld/core/data/models/user_model.dart';

class AuthSessionDto {
  final String serverOrigin;
  final String sessionCredential;
  final String? bearerToken;
  final UserModel userModel;
  final DateTime createdAt;

  const AuthSessionDto({
    required this.serverOrigin,
    required this.sessionCredential,
    required this.userModel,
    required this.createdAt,
    this.bearerToken,
  });

  factory AuthSessionDto.create({
    required String serverOrigin,
    required String sessionCredential,
    required UserModel userModel,
    String? bearerToken,
  }) {
    return AuthSessionDto(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      userModel: userModel,
      createdAt: DateTime.now().toUtc(),
      bearerToken: bearerToken,
    );
  }

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final rawToken = json['bearerToken'];
    return AuthSessionDto(
      serverOrigin: json['serverOrigin'] as String,
      sessionCredential: json['sessionCredential'] as String,
      userModel: UserModel.fromJson(json['userModel'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      bearerToken: rawToken is String && rawToken.trim().isNotEmpty
          ? rawToken.trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverOrigin': serverOrigin,
      'sessionCredential': sessionCredential,
      if (bearerToken != null) 'bearerToken': bearerToken,
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
      bearerToken: bearerToken,
    );
  }

  factory AuthSessionDto.fromEntity(AuthSession entity) {
    return AuthSessionDto(
      serverOrigin: entity.serverOrigin,
      sessionCredential: entity.sessionCredential,
      userModel: UserModel.fromEntity(entity.user),
      createdAt: entity.createdAt,
      bearerToken: entity.bearerToken,
    );
  }
}

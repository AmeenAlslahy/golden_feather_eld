import 'package:golden_feather_eld/core/domain/entities/user.dart';

class AccountUserModel extends User {
  const AccountUserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.fullName,
    super.phone,
    required super.role,
    super.isActive = true,
    super.lastLogin,
    required super.createdAt,
    super.attributes = const {},
  });

  factory AccountUserModel.fromEntity(User user) {
    return AccountUserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
      attributes: user.attributes,
    );
  }

  factory AccountUserModel.fromJson(Map<String, dynamic> json,
      {String? defaultEmail}) {
    final idValue = json['id']?.toString() ?? '';
    final nameValue =
        json['name']?.toString() ?? json['fullName']?.toString() ?? '';
    final emailValue =
        json['email']?.toString() ?? json['username']?.toString() ?? nameValue;

    UserRole userRole = UserRole.fieldWorker;
    if (json['administrator'] == true) {
      userRole = UserRole.admin;
    } else if (json['role'] != null) {
      userRole = UserRole.fromCode(json['role'] as String);
    }

    final isActive = json['disabled'] != null
        ? !(json['disabled'] as bool)
        : (json['isActive'] as bool? ?? true);

    return AccountUserModel(
      id: idValue,
      username: emailValue,
      email: emailValue,
      fullName: nameValue,
      phone: json['phone']?.toString(),
      role: userRole,
      isActive: isActive,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.code,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'attributes': attributes,
    };
  }
}
